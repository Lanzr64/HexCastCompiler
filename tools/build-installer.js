// Build the self-contained CraftOS installer with Node.js. No npm packages needed.
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const files = [
    "hexMap",
    "hccConfig.lua",
    "hex.lua",
    "hex_old.lua",
    "hedit.lua",
    "iotaTools.lua",
    "iotaBridge.lua",
    "startup.lua",
];

function archive() {
    const parts = [Buffer.from([files.length])];
    for (const name of files) {
        const filename = Buffer.from(name, "utf8");
        const content = fs.readFileSync(path.join(root, name));
        if (filename.length > 255) throw new Error(`Filename too long: ${name}`);
        const length = Buffer.alloc(4);
        length.writeUInt32BE(content.length);
        parts.push(Buffer.from([filename.length]), filename, length, content);
    }
    return Buffer.concat(parts);
}

// 8 tokens per control byte. A set bit denotes a two-byte (offset,length) match.
function compress(input) {
    const out = [];
    const recent = new Map();
    function add(position) {
        if (position + 2 >= input.length) return;
        const key = (input[position] << 16) | (input[position + 1] << 8) | input[position + 2];
        const positions = recent.get(key) || [];
        positions.push(position);
        while (positions.length > 64 || position - positions[0] > 4095) positions.shift();
        recent.set(key, positions);
    }
    let position = 0;
    while (position < input.length) {
        const controlAt = out.length;
        out.push(0);
        for (let bit = 0; bit < 8 && position < input.length; bit++) {
            let bestLength = 0;
            let bestOffset = 0;
            if (position + 2 < input.length) {
                const key = (input[position] << 16) | (input[position + 1] << 8) | input[position + 2];
                const positions = recent.get(key) || [];
                for (let i = positions.length - 1; i >= 0; i--) {
                    const offset = position - positions[i];
                    if (offset > 4095) break;
                    let length = 0;
                    while (length < 18 && position + length < input.length
                        && input[positions[i] + length] === input[position + length]) length++;
                    if (length > bestLength) {
                        bestLength = length;
                        bestOffset = offset;
                        if (length === 18) break;
                    }
                }
            }
            if (bestLength >= 3) {
                out[controlAt] |= 1 << bit;
                const token = (bestOffset << 4) | (bestLength - 3);
                out.push(token >> 8, token & 255);
                for (let i = 0; i < bestLength; i++) add(position + i);
                position += bestLength;
            } else {
                out.push(input[position]);
                add(position);
                position++;
            }
        }
    }
    return Buffer.from(out);
}

function adler32(buffer) {
    let a = 1, b = 0;
    for (const value of buffer) {
        a = (a + value) % 65521;
        b = (b + a) % 65521;
    }
    return b * 65536 + a;
}

const plain = archive();
const packed = compress(plain);
const base64 = packed.toString("base64");
const lines = base64.match(/.{1,120}/g).map(line => `    "${line}",`).join("\n");
const template = fs.readFileSync(path.join(__dirname, "installer-runtime.lua"), "utf8");
const installer = template
    .replace("__PAYLOAD__", lines)
    .replace("__UNPACKED_SIZE__", String(plain.length))
    .replace("__ADLER32__", String(adler32(plain)));
const output = path.join(root, "HCCInstaller.lua");
fs.writeFileSync(output, installer);
console.log(`Built ${output} (${plain.length} bytes unpacked, ${packed.length} bytes packed).`);
