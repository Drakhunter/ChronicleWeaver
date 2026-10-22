// scripts/build-media.mjs
// Usage: npm install sharp && node scripts/build-media.mjs
import fs from 'node:fs/promises';
import path from 'node:path';
import sharp from 'sharp';

const SVG_DIR = path.resolve('./Media/svg');
const OUT_DIR = path.resolve('./Media');

// Encodes raw RGBA buffer into an uncompressed 32-bit top-left origin TGA buffer for WoW
function encodeRGBAtoTGA(rgbaBuffer, width, height) {
  const header = Buffer.alloc(18, 0);
  header[2] = 2; // Uncompressed True-Color
  header.writeUInt16LE(width, 12);
  header.writeUInt16LE(height, 14);
  header[16] = 32; // 32 bits per pixel
  header[17] = 0x20 | 0x08; // Top-left origin + 8-bit alpha channel

  const pixels = Buffer.alloc(width * height * 4);
  for (let i = 0; i < width * height; i++) {
    const idx = i * 4;
    pixels[idx] = rgbaBuffer[idx + 2];     // B
    pixels[idx + 1] = rgbaBuffer[idx + 1]; // G
    pixels[idx + 2] = rgbaBuffer[idx];     // R
    pixels[idx + 3] = rgbaBuffer[idx + 3]; // A
  }
  return Buffer.concat([header, pixels]);
}

async function buildMedia() {
  await fs.mkdir(OUT_DIR, { recursive: true });
  const files = (await fs.readdir(SVG_DIR)).filter(f => f.endsWith('.svg'));

  for (const file of files) {
    const svgPath = path.join(SVG_DIR, file);
    const outName = file.replace(/\.svg$/, '.tga');
    const outPath = path.join(OUT_DIR, outName);

    const { data, info } = await sharp(svgPath)
      .ensureAlpha()
      .raw()
      .toBuffer({ resolveWithObject: true });

    const tgaBuffer = encodeRGBAtoTGA(data, info.width, info.height);
    await fs.writeFile(outPath, tgaBuffer);
    console.log(`✅ Built WoW texture: Media/${outName} (${info.width}x${info.height})`);
  }
}

buildMedia().catch(console.error);