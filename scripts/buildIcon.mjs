import fs from "fs"
import path from "path"
import { execSync } from "child_process"

process.chdir(
  path.dirname(import.meta.url.replace(/^file:\/\/\/?/, "")) + "/.."
)
const currentDir = process.cwd()
const buildDir = currentDir + "/dist"

const iconFile = currentDir + "/images/icon/icon.png"
const iconDir = buildDir + "/icon.iconset"

const exec = (command) => {
  console.log("> " + command)
  execSync(command)
}

fs.mkdirSync(iconDir, { recursive: true })
;[16, 32, 128, 256, 512].forEach((size) => {
  exec(
    `magick convert -resize ${size}:${size}! "${iconFile}" "${iconDir}/icon_${size}x${size}.png"`
  )
  if (size === 16 || size === 32) return
  fs.copyFileSync(
    `${iconDir}/icon_${size}x${size}.png`,
    `${iconDir}/icon_${size / 2}x${size / 2}@2x.png`
  )
})

try {
  exec(`iconutil -c icns "${iconDir}" -o "${buildDir}/icon.icns"`)
} catch (e) {
  console.log("iconutil not found, skipping icns build")
}

exec(
  `magick convert "${iconFile}" -define icon:auto-resize "${buildDir}/icon.ico"`
)
