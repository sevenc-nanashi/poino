<script setup lang="ts">
import { Text } from "../text"
import type { Voice } from "../text"
import { computed, onMounted, onUnmounted, ref, toRaw, watch } from "vue"
import { windowListener } from "../windowListener"

const props = defineProps<{ speed?: number }>()
const emit = defineEmits<{
  (e: "updateText", text: Text): void
}>()

const saved = ref<boolean>(true)
const voices = ref<Voice[]>([])
const voice = ref<Voice | undefined>()
const texts = ref<Text[]>([])
const text = computed<Text | undefined>({
  get: () => {
    const filtered = texts.value.filter((text) => text.selected)
    return filtered.length > 0 ? filtered[0] : undefined
  },
  set: (text) => {
    if (text === undefined) return
    texts.value = texts.value.map((text) => {
      text.selected = false
      return text
    })
    text.selected = true
    emit("updateText", text)
  },
})
const showVoiceSelector = ref<boolean>(false)
const player = ref<HTMLAudioElement>(new Audio())
const playing = ref<boolean>(false)
const playingIndex = ref<number>(0)
const cacheFilePaths = ref<string[]>([])
const opening = ref<boolean>(false)
const saving = ref<boolean>(false)
const exporting = ref<boolean>(false)
const history = ref<any[][]>([])
const historyIndex = ref<number>(-1)

function addText() {
  if (!voice) return
  const maxLen = 999
  if (texts.value.length >= maxLen) return
  const text = new Text(voice.value)
  texts.value.push(text)
  saved.value = false
  updateProject()
}
function removeText(text: Text) {
  texts.value = texts.value.filter((x) => x !== text)
  text = undefined
  saved.value = false
  updateProject()
}
function selectText(text: Text) {
  unselectTexts()
  text.selected = true
  text = text
}
function unselectTexts() {
  texts.value.forEach((text) => (text.selected = false))
}
function updateVoice(voice: Voice) {
  voice = voice
  if (text.value && text.value.voiceId !== voice.id) {
    text.value.voiceId = voice.id
    text.value.cacheClear()
    saved.value = false
    updateProject()
  }
  showVoiceSelector.value = false
}
function playVoice(all = false) {
  if (!all && !text) return

  if (!playing.value) {
    playing.value = true
  } else {
    playing.value = false
    return
  }

  const currentTexts = all ? texts.value : [text.value]

  Promise.all(
    currentTexts
      .filter((text) => text.labels.length > 0)
      .map((text) => {
        return text.cacheFile
          ? Promise.resolve(text.cacheFile)
          : text.text2voice()
      })
  )
    .then((filePaths) => {
      cacheFilePaths.value = filePaths
      if (cacheFilePaths.value.length <= 0) {
        playing.value = false
        return
      }

      const filePath = cacheFilePaths[playingIndex.value]
      playingIndex.value = 0
      player.value.src = filePath
      selectTextByCacheFile(filePath)
      player.value.play()
    })
    .catch(console.error)
}
function selectTextByCacheFile(filePath: string) {
  const filtered = texts.value.filter((text) => text.cacheFile === filePath)
  if (filtered.length <= 0) return
  selectText(filtered[0])
}
function moveText(text: Text, direction: string) {
  const index = texts.value.indexOf(text)
  if (index === -1) return

  const newIndex = direction === "up" ? index - 1 : index + 1
  if (newIndex < 0 || newIndex > texts.value.length - 1) return

  const filtered = texts.value.filter((x) => x !== text)
  filtered.splice(newIndex, 0, text)

  texts.value = filtered
  saved.value = false
  updateProject()
}
function getIcon(voiceId: string) {
  const filtered = voices.value.filter((voice) => voice.id === voiceId)
  return filtered.length > 0 ? filtered[0].icon : ""
}
function openProject() {
  if (!voice.value) return

  if (opening.value) return
  opening.value = true
  ;(window as any).project
    .open(!saved.value)
    .then((newTexts: Text[] | null) => {
      if (newTexts === null) return
      if (newTexts.length <= 0) return

      texts.value = newTexts.map((text) => {
        const filtered = voices.value.filter(
          (voice) => voice.id === text.voiceId
        )
        const voice = filtered.length > 0 ? filtered[0] : voices.value[0]

        return new Text(
          voice,
          text.text,
          text.labels,
          text.speed,
          text.volume,
          text.pitchMax,
          text.pitchMin
        )
      })

      selectText(newTexts[0])
      saved.value = true
      updateProject()
    })
    .catch(console.error)
    .finally(() => (opening.value = false))
}
function saveProject(newSave = false) {
  if (saving.value) return
  saving.value = true

  const textObjects = toRaw(texts.value).map((text) => {
    return {
      text: text.text,
      labels: text.labels,
      speed: text.speed,
      volume: text.volume,
      pitchMax: text.pitchMax,
      pitchMin: text.pitchMin,
      voiceId: text.voiceId,
    }
  })

  const data = JSON.stringify(textObjects)

  ;(window as any).project
    .save(data, newSave)
    .then((success: boolean | null) => {
      if (success) {
        saved.value = true
      }
    })
    .catch(console.error)
    .finally(() => (saving.value = false))
}
function exportWav(all = false) {
  if (exporting.value) return
  exporting.value = true

  Promise.all(
    (all ? texts.value : text.value ? [text.value] : [])
      .filter((text) => text.labels.length > 0)
      .map((text) => {
        return text.cacheFile
          ? Promise.resolve(text.cacheFile)
          : text.text2voice()
      })
  )
    .then((filePaths) => {
      cacheFilePaths.value = filePaths

      const files = toRaw(cacheFilePaths.value).map((filePath) => {
        const filteredText = texts.value.filter(
          (text) => text.cacheFile === filePath
        )
        const index =
          filteredText.length > 0 ? texts.value.indexOf(filteredText[0]) + 1 : 0
        const text = filteredText.length > 0 ? filteredText[0].text : "？？？"
        const voiceId =
          filteredText.length > 0 ? filteredText[0].voiceId : "？？？"

        const filteredVoice = voices.value.filter(
          (voice) => voice.id === voiceId
        )
        const voiceName =
          filteredVoice.length > 0 ? filteredVoice[0].name : "？？？"

        const fileName = `${("000" + index).slice(-3)}_${voiceName}_${
          text.length < 10 ? text : text.slice(0, 9) + "…"
        }.wav`

        return { name: fileName, path: filePath }
      })

      return (window as any).wav.export(files)
    })
    .catch(console.error)
    .finally(() => (exporting.value = false))
}
function updateProject() {
  window.dispatchEvent(new Event("updateProject"))
}
function loadFromHistory() {
  const textHistory = history[historyIndex.value]
  texts.value = textHistory.map((text) => {
    return new Text(
      text.voice,
      text.text,
      text.labels,
      text.speed,
      text.volume,
      text.pitchMax,
      text.pitchMin,
      text.selected
    )
  })

  const filtered = texts.value.filter((x) => x.selected)
  if (filtered.length > 0) {
    selectText(filtered[0])
  } else {
    text.value = undefined
    unselectTexts()
  }
}
watch(
  text,
  (newVal: Text | undefined, oldVal: Text | undefined) => {
    newVal = toRaw(newVal)
    oldVal = toRaw(oldVal)

    const newId = newVal?.id
    const oldId = oldVal?.id

    if (newId && oldId && newId === oldId) {
      saved.value = false
    }
  },
  { deep: true }
)

watch(playing, () => {
  if (playing.value) return
  player.value.pause()
  playingIndex.value = 0
  cacheFilePaths.value = []
  player.value.src = ""
})
const [onMount, onUnmount] = windowListener({
  updateProject: () => {
    const filtered = texts.value.filter((text) => text.id === text?.id)
    const selectedId = filtered.length > 0 ? filtered[0].id : null

    const textObjects = JSON.parse(JSON.stringify(toRaw(texts.value))).map(
      (text: any) => {
        const filtered = voices.value.filter(
          (voice) => voice.id === text.voiceId
        )
        const voice = filtered.length > 0 ? filtered[0] : voices[0]

        return {
          voice: voice,
          text: text.text,
          labels: text.labels,
          speed: text.speed,
          volume: text.volume,
          pitchMax: text.pitchMax,
          pitchMin: text.pitchMin,
          selected: text.id === selectedId,
        }
      }
    )

    const isLast = historyIndex.value === history.value.length - 1
    if (!isLast) {
      history.value = history.value.slice(0, historyIndex.value + 1)
    }

    history.value.push(textObjects)
    historyIndex.value++
  },

  undo: () => {
    if (historyIndex.value <= 0) return
    historyIndex.value--
    loadFromHistory()
  },

  redo: () => {
    if (historyIndex.value >= history.value.length - 1) return
    historyIndex.value++
    loadFromHistory()
  },

  beforeinput: (event) => {
    const inputType = (event as InputEvent).inputType

    if (["historyUndo", "historyRedo"].includes(inputType)) {
      event.preventDefault()

      if (inputType === "historyUndo") {
        window.dispatchEvent(new Event("undo"))
      } else if (inputType === "historyRedo") {
        window.dispatchEvent(new Event("redo"))
      }
    }
  },
  openProject: () => {
    openProject()
  },

  newSaveProject: () => {
    saveProject(true)
  },

  overwriteSaveProject: () => {
    saveProject()
  },

  exportWav: () => {
    exportWav()
  },

  exportWavAll: () => {
    exportWav(true)
  },

  reqProjectIsSaved: () => {
    window.dispatchEvent(
      new CustomEvent("resProjectIsSaved", {
        detail: saved,
      })
    )
  },
})
onMounted(() => {
  onMount()
  player.value.addEventListener("ended", () => {
    playingIndex.value++
    if (playingIndex.value >= cacheFilePaths.value.length) {
      playing.value = false
      return
    }

    const waitTimeMs = 500

    setTimeout(() => {
      const filePath = cacheFilePaths[playingIndex.value]
      player.value.src = filePath
      selectTextByCacheFile(filePath)
      player.value.play()
    }, waitTimeMs)
  })
  ;(window as any).voices
    .get()
    .then((newVoices: Voice[]) => {
      if (newVoices.length <= 0) return
      voices.value = newVoices
      voice.value = voices.value[0]
      texts.value.push(new Text(voice.value))
      updateProject()
    })
    .catch(console.error)
})
onUnmounted(() => {
  onUnmount()
})
</script>

<template>
  <div id="texts">
    <div class="wrapper" @click="unselectTexts">
      <div class="text" v-for="text in texts" @click.stop>
        <button class="change-voice-button">
          <img
            class="back"
            v-bind:src="getIcon(text.voiceId)"
            @click="selectText(text), (showVoiceSelector = true)"
          />
        </button>
        <input
          placeholder="ここにテキストを入力"
          v-model="text.text"
          @click="selectText(text)"
          @input="text.cacheClear()"
          @change="text.text2label()"
          v-bind:class="[text.selected ? 'selected' : '']"
        />
        <button
          class="move-up-button"
          @click="moveText(text, 'up')"
          v-if="texts.length > 1"
        ></button>
        <button
          class="move-down-button"
          @click="moveText(text, 'down')"
          v-if="texts.length > 1"
        ></button>
        <button
          class="remove-text-button"
          @click="removeText(text)"
          v-if="texts.length > 1"
        >
          <div class="back"></div>
          <div class="line"></div>
          <div class="line"></div>
        </button>
      </div>
    </div>
    <div class="buttons">
      <button class="play-voice-button" @click="playVoice()">
        <div class="back"></div>
        <div class="triangle" v-if="!playing">
          <div class="line-box">
            <div class="line"></div>
          </div>
          <div class="line-box">
            <div class="line"></div>
          </div>
          <div class="line-box">
            <div class="line"></div>
          </div>
          <div class="fill"></div>
        </div>
        <div class="pause" v-else>
          <div class="box"></div>
          <div class="box"></div>
        </div>
      </button>
      <button class="play-voice-all-button" @click="playVoice(true)">
        <div class="back"></div>
        <div class="triangle" v-if="!playing">
          <div class="line-box">
            <div class="line"></div>
          </div>
          <div class="line-box">
            <div class="line"></div>
          </div>
          <div class="line-box">
            <div class="line"></div>
          </div>
          <div class="fill"></div>
        </div>
        <div class="triangle" v-if="!playing">
          <div class="line-box">
            <div class="line"></div>
          </div>
          <div class="line-box">
            <div class="line"></div>
          </div>
          <div class="line-box">
            <div class="line"></div>
          </div>
          <div class="fill"></div>
        </div>
        <div class="pause" v-else>
          <div class="box"></div>
          <div class="box"></div>
        </div>
      </button>
      <button class="add-text-button" @click="addText">
        <div class="back"></div>
        <div class="line"></div>
        <div class="line"></div>
      </button>
    </div>
  </div>
  <div
    id="voice-selector"
    @click="showVoiceSelector = false"
    v-if="showVoiceSelector"
  >
    <div class="dialog" @click.stop>
      <p class="label">声を選択</p>
      <div class="wrapper">
        <button
          class="voice"
          v-for="voice in voices"
          @click="updateVoice(voice)"
        >
          <img class="back" v-bind:src="voice.icon" />
          <p>{{ voice.name }}</p>
        </button>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
#texts {
  width: calc(100% - 300px - 24px); // params, margin
  height: calc(
    100% - 46px - 250px - 21px - 24px
  ); // menus, adjusters, progress, margin
  position: relative;
  margin: 16px 8px 8px 16px;
  border-radius: 8px;
  background-color: var(--color-main);
}

.wrapper {
  width: calc(100% - 16px); // margin
  height: calc(100% - 16px); // margin
  margin: 8px;
  overflow-y: scroll;
}

.text {
  width: calc(100% - 16px); // margin
  height: fit-content;
  position: relative;
  margin: 16px 8px;
  margin-bottom: 0;
  display: flex;
  justify-content: flex-start;
  align-items: flex-start;

  .change-voice-button {
    width: 46px;
    height: 46px;
    margin-right: 16px;

    img {
      width: 100%;
      height: 100%;
      border: 3px solid var(--color-line-main);
      border-radius: 8px;
    }
  }

  input {
    width: calc(100% - 62px); // img
    height: 46px;
    min-height: 46px;
    max-height: 200px;
    padding: 8px;
    border: 3px solid var(--color-line-main);
    border-radius: 8px;
    resize: vertical;
    font-size: 16px;
    color: var(--color-text-main);
    transition: border-color 0.2s;

    &::placeholder {
      color: var(--color-text-main);
      opacity: 0.5;
    }

    &.selected {
      border-color: var(--color-line-sub);
    }
  }

  .move-up-button,
  .move-down-button {
    width: 0;
    height: 0;
    position: absolute;
    margin: auto;
    right: 44px;
    border-left: 8px solid transparent;
    border-right: 8px solid transparent;
    border-bottom: 12px solid var(--color-sub);
    opacity: 0;
    transition: transform 0.2s, opacity 0.2s;
  }

  .move-up-button {
    top: 8px;

    &:hover {
      transform: scale(1.1);
    }

    &:active {
      transform: scale(0.9);
    }
  }

  .move-down-button {
    bottom: 8px;
    transform: rotateZ(180deg);

    &:hover {
      transform: rotateZ(180deg) scale(1.1);
    }

    &:active {
      transform: rotateZ(180deg) scale(1);
    }
  }

  .remove-text-button {
    width: 24px;
    height: 24px;
    position: absolute;
    margin: auto;
    top: 0;
    right: 11px;
    bottom: 0;
    opacity: 0;
    transition: opacity 0.2s;

    .back {
      width: 100%;
      height: 100%;
      position: absolute;
      margin: auto;
      top: 0;
      left: 0;
      border-radius: 50%;
      background-color: var(--color-sub);
    }

    .line {
      width: 12px;
      height: 3px;
      position: absolute;
      margin: auto;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      border-radius: 2px;
      background-color: var(--color-main);

      &:nth-child(2) {
        transform: rotateZ(45deg);
      }
      &:nth-child(3) {
        transform: rotateZ(-45deg);
      }
    }
  }

  &:first-child {
    margin-top: 8px;
  }

  &:last-child {
    margin-bottom: 64px;
  }

  &:hover {
    button {
      opacity: 1;
    }
  }
}

.buttons {
  width: fit-content;
  height: fit-content;
  position: absolute;
  margin: auto;
  right: 12px;
  bottom: 12px;

  button {
    width: 50px;
    height: 50px;
    position: relative;

    &:not(:last-child) {
      margin-right: 12px;
    }

    .back {
      width: 100%;
      height: 100%;
      position: absolute;
      margin: auto;
      top: 0;
      left: 0;
      border-radius: 50%;
      background-color: var(--color-sub);
    }
  }

  .play-voice-button,
  .play-voice-all-button {
    .triangle {
      width: 30px;
      height: 30px;
      position: absolute;
      margin: auto;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;

      .line-box {
        width: 18px;
        height: 18px * 0.75;
        position: absolute;
        margin: auto;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;

        .line {
          width: 100%;
          height: 4px;
          position: absolute;
          margin: auto;
          top: 0;
          left: 0;
          border-radius: 2px;
          background-color: var(--color-main);
        }

        &:nth-child(1) {
          transform: rotateZ(30deg);
        }
        &:nth-child(2) {
          transform: rotateZ(-90deg);
        }
        &:nth-child(3) {
          transform: rotateZ(150deg);
        }
      }

      .fill {
        width: 0;
        height: 0;
        position: absolute;
        margin: auto;
        top: 0;
        left: 4px;
        right: 0;
        bottom: 0;
        border-style: solid;
        border-width: 8px 0 8px 16px;
        border-color: transparent transparent transparent var(--color-main);
      }
    }

    .pause {
      width: 20px;
      height: 20px;
      position: absolute;
      margin: auto;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;

      .box {
        width: 5px;
        height: 20px;
        position: absolute;
        margin: auto;
        top: 0;
        border-radius: 2px;
        background-color: var(--color-main);

        &:nth-child(1) {
          left: 1px;
        }
        &:nth-child(2) {
          right: 1px;
        }
      }
    }
  }

  .play-voice-all-button {
    .triangle {
      &:nth-child(2) {
        transform: translateX(-8px);
      }
      &:nth-child(3) {
        transform: translateX(6px);
      }
    }
  }

  .add-text-button {
    .line {
      width: 30px;
      height: 5px;
      position: absolute;
      margin: auto;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      border-radius: 2.5px;
      background-color: var(--color-main);

      &:nth-child(3) {
        transform: rotateZ(90deg);
      }
    }
  }
}

#voice-selector {
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
    width: 400px;
    height: 300px;
    border: 3px solid var(--color-line-sub);
    border-radius: 8px;
    background-color: var(--color-main);

    .label {
      width: 100%;
      font-size: 16px;
      font-weight: 700;
      line-height: 40px;
      text-align: center;
      color: var(--color-text-main);
    }

    .wrapper {
      width: calc(100% - 24px); // margin
      height: calc(100% - 40px - 8px); // label, margin
      margin: 8px;
      margin-top: 0;
      margin-left: 16px;
      overflow-y: scroll;
      display: flex;
      flex-wrap: wrap;
      justify-content: flex-start;
      align-items: flex-start;
      align-content: flex-start;

      .voice {
        width: calc(50% - 12px); // margin
        height: fit-content;
        margin-bottom: 16px;
        border: 3px solid var(--color-line-main);
        border-radius: 8px;
        overflow: hidden;
        background-color: var(--color-main);
        display: flex;
        flex-direction: column;
        justify-content: flex-start;
        align-items: center;

        &:nth-child(odd) {
          margin-right: 16px;
        }

        img {
          width: 50px;
          height: 50px;
          margin-top: 8px;
          border-radius: 8px;
        }

        p {
          font-size: 14px;
          font-weight: 700;
          line-height: 30px;
          color: var(--color-text-main);
        }
      }
    }
  }
}
</style>
