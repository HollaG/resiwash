// sensorStabilizer.js
const MAX_HISTORY = 7;

export default class SensorStabilizer {
  private history: number[];

  constructor() {
    this.history = [];
  }

  // 0, 0,0 , 0, 0, 0,0,0,0,1, 0, 1, 0 , 0, 1, 1,1 1, ,0 ,1, 1,
  update(value: number): number {
    this.history.push(value);
    if (this.history.length > MAX_HISTORY) {
      this.history.shift(); // keep only last 7 values
    }

    if (this.history.length < MAX_HISTORY) {
      // we haven't hit the full 6 values yet, so just pass along whatever data we have
      return value;
    }

    const mostFreq = mostFreqEle(this.history)
    console.log(`last 7 values are ${this.history.join(", ")}. saving ${mostFreq}`)

    // return the most common item in the history
    return mostFreq
  }
}


function mostFreqEle(arr: number[]) {
  let n = arr.length, maxcount = 0;
  let res = 0;

  for (let i = 0; i < n; i++) {
    let count = 0;
    for (let j = 0; j < n; j++) {
      if (arr[i] === arr[j])
        count++;
    }

    // If count is greater or if count 
    // is same but value is bigger.
    if (count > maxcount || (count === maxcount && arr[i] > res)) {
      maxcount = count;
      res = arr[i];
    }
  }

  return res;
}

module.exports = SensorStabilizer;
