import { defineConfig } from "vite"
import electron from "vite-electron-plugin"
import vue from "@vitejs/plugin-vue"

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    electron({
      include: ["./electron"],
    }),
  ],
	root: "./renderer"
})
