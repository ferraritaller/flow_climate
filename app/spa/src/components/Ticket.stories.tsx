import { ComponentStory, ComponentMeta } from "@storybook/react"

import Ticket from "./Ticket"

export default {
  title: "Ticket",
  component: Ticket,
} as ComponentMeta<typeof Ticket>

export const Primary: ComponentStory<typeof Ticket> = () => (
  <Ticket title="Custo" value="R$ 175.000,00" />
)

export const WithUnit: ComponentStory<typeof Ticket> = () => (
  <Ticket title="Envelhecimento" value="35" unity="dias" />
)
