import { Company } from "../company/company.types"
import { Project } from "../project/project.types"
import ControlChart from "../charts/controlChart.types"
import { TeamMember } from "../teamMember/teamMember.types"
import { DemandsFlowChartData, NumberChartData } from "../charts/charts.types"
import { Product } from "../product/product.types"
import { Customer } from "../customer/customer.types"

export type Demand = {
  id: string
  demandTitle?: string
  demandType: string
  endDate?: string
  commitmentDate?: string
  createdDate: string
  product?: Product
  customer?: Customer
  responsibles?: TeamMember[]
  externalId: string
  leadtime: number
  project?: Project
  company?: Company
  costToProject?: number
  effortUpstream?: number
  effortDownstream?: number
  portfolioUnit?: PortfolioUnit
  projectName: string
  productName: string
  demandBlocksCount: number
}

type PortfolioUnit = {
  id: string
  name: string
}

export type DemandsList = {
  demands: Demand[]
  lastPage: boolean
  totalCount: number
  totalPages: number
  totalEffort?: number
  controlChart: ControlChart
  leadTimeBreakdown: NumberChartData
  flowData: DemandsFlowChartData
  flowEfficiency: NumberChartData
  leadTimeEvolutionP80: NumberChartData
}

export type DemandBlock = {
  id: string
  demand?: Demand
  blockTime?: string
  unblockTime?: string
}

export type DemandBlocksList = {
  demandBlocks: DemandBlock[]
}
