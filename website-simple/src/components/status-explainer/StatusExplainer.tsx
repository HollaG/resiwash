import { Flex, Group, Text, Tooltip } from "@mantine/core"
import { StatusIndicator } from "../status-indicator/StatusIndicator"
import { MachineStatus } from "../../types/datatypes"

import styles from "./index.module.css"
import { getTextColorForMachineStatus } from "../../utils/indicatorHelper"
import { IconHelpCircle } from "@tabler/icons-react"
export const StatusExplainer = () => {
  return <Group preventGrowOverflow={false} style={{
    flexWrap: 'nowrap',
    overflowX: 'auto',
    gap: '12px',
    justifyContent: "end"
  }}>
    {/* <Text c="dimmed">
      Legend
    </Text>
    <Divider orientation="vertical" /> */}
    <Flex className={styles["explainer-item"]}  >
      <StatusIndicator status={MachineStatus.AVAILABLE} />
      <Tooltip label={"This machine is available"} withArrow events={{ hover: true, focus: true, touch: true }}>
        <Flex className={styles["explainer-item-text"]}>

          <Text style={{
            color: getTextColorForMachineStatus(MachineStatus.AVAILABLE),

          }}>
            Available
          </Text>
          <IconHelpCircle size={14} className={styles["explainer-help-icon"]} />
        </Flex>

      </Tooltip>
    </Flex>
    <Flex className={styles["explainer-item"]}  >
      <StatusIndicator status={MachineStatus.IN_USE} />
      <Tooltip label={"This machine is currently in use"} withArrow events={{ hover: true, focus: true, touch: true }}>
        <Flex className={styles["explainer-item-text"]}>

          <Text style={{
            color: getTextColorForMachineStatus(MachineStatus.IN_USE),

          }}>
            In Use
          </Text>
          <IconHelpCircle size={14} className={styles["explainer-help-icon"]} />
        </Flex>

      </Tooltip>
    </Flex>
    <Flex className={styles["explainer-item"]}  >
      <StatusIndicator status={MachineStatus.FINISHING} />
      <Tooltip label={"This machine is on its last cycle. It should finish within 10 minutes."} withArrow events={{ hover: true, focus: true, touch: true }} multiline
        w={220}>
        <Flex className={styles["explainer-item-text"]}>

          <Text style={{
            color: getTextColorForMachineStatus(MachineStatus.FINISHING),

          }}>
            Finishing
          </Text>
          <IconHelpCircle size={14} className={styles["explainer-help-icon"]} />
        </Flex>

      </Tooltip>
    </Flex>

  </Group>
}

