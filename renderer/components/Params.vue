<script setup lang="ts">
import { computed, Ref, ref, watch } from "vue"
import { Text } from "../text"
import { extractNumbers } from "../utils"

interface Config {
  min: number
  max: number
  step: number
  val: number
  limit?: {
    min: number
    max: number
  }
}

const props = defineProps<{
  text: Text | undefined
}>()
const voiceId = ref<string | undefined>(undefined)
const speed = ref<Config>({
  min: 0.5,
  max: 2.0,
  step: 0.1,
  val: 1.0,
})
const volume = ref<Config>({ min: 0.0, max: 2.0, step: 0.1, val: 1.0 })
const pitchMax = ref<Config>({
  min: 100,
  max: 800,
  step: 1,
  val: 400,
  limit: {
    min: 0,
    max: 5000,
  },
})
const pitchMin = ref<Config>({
  min: 100,
  max: 800,
  step: 1,
  val: 400,
  limit: {
    min: 0,
    max: 5000,
  },
})

function onUpdate(element: Ref<Config>) {
  return function update(event: Event) {
    if (event.target === null) return
    const target = event.target as HTMLInputElement
    const [min, max] = [
      element.value.limit ? element.value.limit.min : element.value.min,
      element.value.limit ? element.value.limit.max : element.value.max,
    ]
    let num = Number(extractNumbers(target.value))
    if (num < min) num = min
    if (num > max) num = max
    updateValues()
    element.value.val = Math.round(num * 100) / 100
    target.value = `${element.value.val}.0`.slice(0, 3)
    if (event.type === "change") {
      updateText()
      updateLabel()
    }
  }
}
const updateSpeed = onUpdate(speed)
const updateVolume = onUpdate(volume)
const updatePitchMax = onUpdate(pitchMax)
const updatePitchMin = onUpdate(pitchMin)

function updateValues() {
  const text = props.text
  if (!text) return
  speed.value.val = text.speed
  volume.value.val = text.volume
  pitchMax.value.val = text.pitchMax
  pitchMin.value.val = text.pitchMin
}
function updateText() {
  const text = props.text
  if (!text) return
  text.speed = speed.value.val
  text.volume = volume.value.val
  text.pitchMax = pitchMax.value.val
  text.pitchMin = pitchMin.value.val
  text.cacheClear()
  voiceId.value = text.voiceId
}
function updateLabel() {
  const text = props.text
  if (!text) return
  text.text2label()
}
function updateProject() {
  window.dispatchEvent(new Event("updateProject"))
}
watch(props, () => {
  const text = props.text
  if (!text) return

  const match = text.voiceId === voiceId.value
  if (text.speed < 0) text.speed = match ? speed.value.val : -text.speed
  if (text.volume < 0) text.volume = match ? volume.value.val : -text.volume
  if (text.pitchMax < 0)
    text.pitchMax = match ? pitchMax.value.val : -text.pitchMax
  if (text.pitchMin < 0)
    text.pitchMin = match ? pitchMin.value.val : -text.pitchMin

  updateValues()
})
const enabled = computed(() => {
  return props.text !== null
})
</script>

<template>
  <div id="params" :class="!text ? 'disabled' : ''">
    <div class="param">
      <p class="label">速度</p>
      <div class="value">
        <input
          type="text"
          :value="`${speed.val}.0`.slice(0, 3)"
          :disabled="!enabled"
          @change="updateSpeed"
        />
      </div>
      <input
        type="range"
        :min="speed.min"
        :max="speed.max"
        :step="speed.step"
        :value="speed.val"
        :disabled="!enabled"
        @input="updateSpeed"
        @change="updateSpeed"
      />
    </div>
    <div class="param">
      <p class="label">音量</p>
      <p class="value">
        <input
          type="text"
          :value="`${volume.val}.0`.slice(0, 3)"
          :disabled="!enabled"
          @change="updateVolume"
        />
      </p>
      <input
        type="range"
        :min="volume.min"
        :max="volume.max"
        :step="volume.step"
        :value="volume.val"
        :disabled="!enabled"
        @input="updateVolume"
        @change="updateVolume"
      />
    </div>
    <div class="param">
      <p class="label">ピッチ上限</p>
      <p class="value">
        <input
          type="text"
          :value="pitchMax.val"
          :disabled="!enabled"
          @change="updatePitchMax"
        />
        <span class="unit">Hz</span>
      </p>
      <input
        type="range"
        :min="pitchMax.min"
        :max="pitchMax.max"
        :step="pitchMax.step"
        :value="pitchMax.val"
        :disabled="!enabled"
        @input="updatePitchMax"
        @change="updatePitchMax"
      />
    </div>
    <div class="param">
      <p class="label">ピッチ下限</p>
      <p class="value">
        <input
          type="text"
          :value="pitchMin.val"
          :disabled="!enabled"
          @change="updatePitchMin"
        />
        <span class="unit">Hz</span>
      </p>
      <input
        type="range"
        :min="pitchMin.min"
        :max="pitchMin.max"
        :step="pitchMin.step"
        :value="pitchMin.val"
        :disabled="!enabled"
        @input="updatePitchMin"
        @change="updatePitchMin"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
#params {
  width: 300px - 24px; // margin
  height: calc(
    100% - 46px - 250px - 21px - 24px
  ); // menus, adjusters, progress, margin
  margin: 16px 16px 8px 8px;
  border-radius: 8px;
  background-color: var(--color-main);
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  align-items: flex-start;

  &.disabled {
    .param {
      filter: opacity(0.5);
    }
  }
}

.param {
  width: calc(100% - 32px); // margin
  height: fit-content;
  margin: 16px;
  margin-bottom: 8px;
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-start;
  align-items: flex-start;

  .label,
  .value {
    width: 50%;
    height: 24px;
    font-size: 14px;
    line-height: 24px;
    color: var(--color-text-main);
  }

  .value {
    display: flex;
    justify-content: flex-end;
    align-items: center;

    input[type="text"] {
      width: 40px;
      height: 100%;
      font-size: 16px;
      text-align: center;
      color: var(--color-text-main);
    }

    .unit {
      margin-left: 4px;
    }
  }

  input[type="range"] {
    width: 100%;
    height: 5px;
    margin: 8px 0;
    border-radius: 2.5px;
    background-color: var(--color-rangebar-main);
    appearance: none;

    &::-webkit-slider-thumb {
      width: 20px;
      height: 20px;
      border-radius: 50%;
      background-color: var(--color-sub);
      -webkit-appearance: none;
    }
  }
}
</style>
