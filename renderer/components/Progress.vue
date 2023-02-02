<script setup lang="ts">
import { ref } from "vue"
import { windowListener } from "../windowListener"

windowListener({
  synthProgress: (event) => {
    const detail = (event as CustomEvent).detail
    progress.value = detail as number

    if (timeoutId.value !== null) {
      clearTimeout(timeoutId.value)
      timeoutId.value = null
    }

    if (progress.value === 1) {
      const delayTimeMs = 3000
      timeoutId.value = setTimeout(() => {
        progress.value = 0
        timeoutId.value = null
      }, delayTimeMs)
    }
  },
})
const progress = ref(0)
const timeoutId = ref<ReturnType<typeof setTimeout> | null>(null)
</script>

<template>
  <div id="progress">
    <div v-bind:style="[`width: ${progress * 100}%;`]"></div>
  </div>
</template>

<style lang="scss" scoped>
#progress {
  width: calc(100% - 32px); // margin
  height: 5px;
  position: relative;
  margin: 16px;
  margin-top: 0;
  border-radius: 2.5px;
  background-color: var(--color-main);

  div {
    height: 100%;
    position: absolute;
    top: 0;
    left: 0;
    border-radius: 2.5px;
    background-color: var(--color-line-sub);
    transition: width 0.1s;
  }
}
</style>
