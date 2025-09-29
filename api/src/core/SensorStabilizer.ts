// import { MachineStatus } from "./types";

// // sensorStabilizer.js
// const MAX_HISTORY = 7;

// export default class SensorStabilizer {
//   private history: MachineStatus[];

//   constructor() {
//     this.history = [];
//   }

//   // 0, 0,0 , 0, 0, 0,0,0,0,1, 0, 1, 0 , 0, 1, 1,1 1, ,0 ,1, 1,
//   update(value: MachineStatus): MachineStatus {
//     this.history.push(value);
//     if (this.history.length > MAX_HISTORY) {
//       this.history.shift(); // keep only last 7 values
//     }

//     if (this.history.length < MAX_HISTORY) {
//       // we haven't hit the full 6 values yet, so just pass along whatever data we have
//       return value;
//     }

//     const mostFreq = mostFreqEle(this.history);
//     console.log(
//       `last 7 values are ${this.history.join(", ")}. saving ${mostFreq}`
//     );

//     // return the most common item in the history
//     return mostFreq;
//   }
// }

// function mostFreqEle(arr: MachineStatus[]) {
//   let n = arr.length,
//     maxcount = 0;
//   let res: MachineStatus | null = null;

//   for (let i = 0; i < n; i++) {
//     let count = 0;
//     for (let j = 0; j < n; j++) {
//       if (arr[i] === arr[j]) count++;
//     }

//     // If count is greater, update the result
//     if (count > maxcount) {
//       maxcount = count;
//       res = arr[i];
//     }
//   }

//   return res;
// }

// module.exports = SensorStabilizer;

import { MachineStatus } from "./types";

const MAX_HISTORY = 7;
const MIN_CONSECUTIVE_COUNT = 3;

export default class SensorStabilizer {
  private history: MachineStatus[];
  private currentStableStatus: MachineStatus | null;

  constructor() {
    this.history = [];
    this.currentStableStatus = null;
  }

  update(value: MachineStatus): MachineStatus {
    this.history.push(value);
    if (this.history.length > MAX_HISTORY) {
      this.history.shift(); // keep only last 7 values
    }

    // If we don't have enough history, return the current stable status or the new value
    if (this.history.length < MIN_CONSECUTIVE_COUNT) {
      if (this.currentStableStatus === null) {
        this.currentStableStatus = value;
      }
      return this.currentStableStatus;
    }

    // Check if the last MIN_CONSECUTIVE_COUNT values are all the same
    const lastValues = this.history.slice(-MIN_CONSECUTIVE_COUNT);
    const allSame = lastValues.every((status) => status === lastValues[0]);

    if (allSame && lastValues[0] !== this.currentStableStatus) {
      // We have at least 3 consecutive same values and it's different from current stable status
      this.currentStableStatus = lastValues[0];
      console.log(
        `Status change detected: last ${MIN_CONSECUTIVE_COUNT} values are ${lastValues.join(
          ", "
        )}. Changing to ${this.currentStableStatus}`
      );
    }

    console.log(
      `History: ${this.history.join(", ")}. Current stable status: ${
        this.currentStableStatus
      }`
    );

    return this.currentStableStatus!;
  }
}

export { SensorStabilizer };
