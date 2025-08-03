import { ComboboxItem, TabsVariant } from "@mantine/core";

export const TabsVariants: Record<TabsVariant, TabsVariant> = {
    default: 'default',
    outline: 'outline',
    pills: 'pills',
}

export const TabsVariantsOptions: ComboboxItem[] = [
    { value: TabsVariants.default, label: 'Default' },
    { value: TabsVariants.outline, label: 'Outline' },
    { value: TabsVariants.pills, label: 'Pills' },
]