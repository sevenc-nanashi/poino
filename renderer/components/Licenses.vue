<script setup lang="ts">
import { onMounted, onUnmounted, ref } from "vue"
import { windowListener } from "../windowListener"

interface Licenses {
  [index: string]: {
    [index: string]: {
      type: string
      repo: string
      text: string
      open?: boolean
    }
  }
}
const showLicenses = ref(false)
const licenses = ref<Licenses | undefined>()

;(window as any).licenses
  .get()
  .then((licensesInfo: Licenses | null) => {
    if (licensesInfo === null) return
    licenses.value = licensesInfo
  })
  .catch(console.error)
const [onMount, onUnmount] = windowListener({
  showLicenses: () => {
    showLicenses.value = true
  },
})
onMounted(() => {
  onMount()
})
onUnmounted(() => {
  onUnmount()
})
</script>

<template>
  <div id="licenses" v-on:click="showLicenses = false" v-if="showLicenses">
    <div class="dialog" v-on:click.stop="">
      <div class="wrapper">
        <div
          class="licenses"
          v-for="(licensesClass, index) in licenses"
          :key="index"
        >
          <div
            class="license-box"
            v-for="(value, key) in licensesClass"
            :key="key"
          >
            <div class="info-box">
              <p class="name">{{ key }}</p>
              <p class="type">type: {{ value.type }}</p>
              <p class="repo">repo: {{ value.repo }}</p>
              <p class="text">
                text:
                <span
                  v-on:click="value.open = !value?.open"
                  v-bind:class="[value?.open ? 'open' : '']"
                >
                  ▶
                </span>
              </p>
            </div>
            <div class="text-box" v-if="value?.open">
              <p
                v-for="text in value.text.split(
                  new RegExp('(\\r\\n|\\n|\\r)', 'gm')
                )"
                :key="text"
              >
                {{ text }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
#licenses {
  width: 100vw;
  height: 100vh;
  position: absolute;
  top: 0;
  left: 0;
  z-index: 1;
  display: flex;
  justify-content: center;
  align-items: center;

  .dialog {
    width: 800px;
    height: 500px;
    border: 3px solid var(--color-line-sub);
    border-radius: 8px;
    background-color: var(--color-main);

    .wrapper {
      width: 100%;
      height: 100%;
      overflow-y: scroll;
      display: flex;
      flex-direction: column;
      justify-content: flex-start;
      align-items: flex-start;
    }

    .licenses {
      width: 100%;
      height: fit-content;
      display: flex;
      flex-direction: column;
      justify-content: flex-start;
      align-items: flex-start;

      &:last-child {
        margin-bottom: 32px;
      }
    }

    .license-box {
      width: calc(100% - 64px); // margin
      height: calc(100% - 64px); // margin
      margin: 32px;
      margin-bottom: 0;

      .info-box {
        width: 100%;
        height: fit-content;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: flex-start;

        p {
          margin-right: 16px;
          font-size: 14px;
          color: var(--color-text-main);
          user-select: text;

          &.name {
            font-weight: 700;
          }

          span {
            font-size: 10px;
            display: inline-block;

            &.open {
              transform: rotateZ(90deg);
            }
          }
        }
      }

      .text-box {
        width: 100%;
        height: fit-content;
        margin-top: 8px;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: flex-start;

        p {
          font-size: 14px;
          color: var(--color-text-main);
          user-select: text;
        }
      }
    }
  }
}
</style>
