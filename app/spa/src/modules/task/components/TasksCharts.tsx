import { gql, useQuery } from "@apollo/client"
import { Grid } from "@mui/material"
import { SliceTooltipProps } from "@nivo/line"
import { useContext, useState } from "react"
import { useTranslation } from "react-i18next"

import { MeContext } from "../../../contexts/MeContext"
import { BarChart } from "../../../components/charts/BarChart"
import { LineChart } from "../../../components/charts/LineChart"
import { ScatterChart } from "../../../components/charts/ScatterChart"
import BarChartTooltip, {
  BarData,
} from "../../../components/charts/tooltips/BarChartTooltip"
import { secondsToDays } from "../../../lib/date"
import { openWindow } from "../../../lib/func"
import { Task } from "../task.types"
import { normalizeTasksFlowChart } from "../normalize"
import TasksList, { TaskFilters } from "./TasksList"
import LineChartTooltip from "../../../components/charts/tooltips/LineChartTooltip"
import { ChartGridItem } from "../../../components/charts/ChartGridItem"
import {
  ChartAxisData,
  KeyValueData,
  SimpleChartData,
} from "../../charts/charts.types"
import PieChart from "../../../components/charts/PieChart"
import ControlChart from "../../charts/controlChart.types"

const TASKS_CHARTS_QUERY = gql`
  query TasksCharts(
    $status: String
    $title: String
    $teamId: ID
    $projectId: ID
    $initiativeId: ID
    $untilDate: ISO8601Date
    $fromDate: ISO8601Date
    $portfolioUnit: String
    $taskType: String
  ) {
    tasksList(
      status: $status
      title: $title
      teamId: $teamId
      projectId: $projectId
      initiativeId: $initiativeId
      untilDate: $untilDate
      fromDate: $fromDate
      portfolioUnit: $portfolioUnit
      taskType: $taskType
    ) {
      totalCount
      completiontimeHistogramChartData {
        keys
        values
      }
      tasks {
        id
        externalId
        delivered
        createdDate
        secondsToComplete
        partialCompletionTime
      }
      controlChart {
        leadTimeP65
        leadTimeP80
        leadTimeP95
        leadTimes
        xAxis
      }
      tasksCharts {
        xAxis
        creation: creationArray
        throughput: throughputArray
        completionPercentilesOnTimeArray
        accumulatedCompletionPercentilesOnTimeArray
      }

      deliveredLeadTimeP65
      deliveredLeadTimeP80
      deliveredLeadTimeP95

      inProgressLeadTimeP65
      inProgressLeadTimeP80
      inProgressLeadTimeP95

      completiontimeHistogramChartData {
        keys
        values
      }
      tasksByType {
        label
        value
      }
      tasksByProject {
        label
        value
      }
    }
  }
`

export type TasksChartsDTO = {
  tasksList: {
    totalCount: number
    tasks: Task[]
    tasksCharts: {
      xAxis: string[]
      creation: number[]
      throughput: number[]
      completionPercentilesOnTimeArray: number[]
      accumulatedCompletionPercentilesOnTimeArray: number[]
    }
    deliveredLeadTimeP65: number
    deliveredLeadTimeP80: number
    deliveredLeadTimeP95: number
    inProgressLeadTimeP65: number
    inProgressLeadTimeP80: number
    inProgressLeadTimeP95: number
    completiontimeHistogramChartData: KeyValueData
    tasksByType?: SimpleChartData[]
    tasksByProject?: SimpleChartData[]
    controlChart?: ControlChart
  }
}

const TaskCharts = () => {
  const { t } = useTranslation("tasks")
  const [taskFilters, setTaskFilters] = useState<TaskFilters>({
    page: 0,
    status: "",
  })
  const { data, loading } = useQuery<TasksChartsDTO>(TASKS_CHARTS_QUERY, {
    variables: {
      ...taskFilters,
    },
  })
  const { me } = useContext(MeContext)

  const taskList = data?.tasksList
  const companySlug = String(me?.currentCompany?.slug)

  const getTaskIDByExternalID = (findedExternalId: number) => {
    return taskList?.tasks.find(
      ({ externalId }) => Number(externalId) === findedExternalId
    )
  }

  const deliveredLeadTimeP65 = secondsToDays(
    Number(taskList?.deliveredLeadTimeP65)
  )
  const deliveredLeadTimeP80 = secondsToDays(
    Number(taskList?.deliveredLeadTimeP80)
  )
  const deliveredLeadTimeP95 = secondsToDays(
    Number(taskList?.deliveredLeadTimeP95)
  )

  const deliveredLeadTimeP65Marker = {
    value: deliveredLeadTimeP65,
    legend: t("charts.control_completion_time_p65_marker", {
      days: deliveredLeadTimeP65,
    }),
  }

  const deliveredLeadTimeP80Marker = {
    value: deliveredLeadTimeP80,
    legend: t("charts.control_completion_time_p80_marker", {
      days: deliveredLeadTimeP80,
    }),
  }

  const deliveredLeadTimeP95Marker = {
    value: deliveredLeadTimeP95,
    legend: t("charts.control_completion_time_p95_marker", {
      days: deliveredLeadTimeP95,
    }),
  }

  const controlChart = data?.tasksList.controlChart
  const completionTimeChartData = {
    xAxis: controlChart?.xAxis.slice(-1000) || [],
    yAxis:
      controlChart?.leadTimes
        .map((lt) => secondsToDays(Number(lt)))
        .slice(-1000) || [],
    leadTimeP65: secondsToDays(Number(controlChart?.leadTimeP65)),
    leadTimeP80: secondsToDays(Number(controlChart?.leadTimeP80)),
    leadTimeP95: secondsToDays(Number(controlChart?.leadTimeP95)),
  }

  const unfinishedTasks = taskList?.tasks
    .filter((task) => !task.delivered)
    .slice(-1000)
  const partialCompletionTimeChartData: ChartAxisData = {
    xAxis: unfinishedTasks?.map((task) => task.externalId || "") || [],
    yAxis:
      unfinishedTasks?.map(
        (task) => secondsToDays(task.partialCompletionTime) || 0
      ) || [],
  }

  const { flowChartGroupNames, flowChartData } =
    normalizeTasksFlowChart(taskList)

  const tasksChartsData = data?.tasksList.tasksCharts
  const completionTimeEvolutionChartData = [
    {
      id: t("charts.completion_time_confidence_p80_legend"),
      data:
        tasksChartsData?.xAxis.map((xAxis, index) => {
          return {
            x: xAxis,
            y: secondsToDays(
              tasksChartsData?.completionPercentilesOnTimeArray[index]
            ),
          }
        }) || [],
    },
    {
      id: t("charts.completion_time_confidence_p80_acumulated_legend"),
      data:
        tasksChartsData?.xAxis.map((xAxis, index) => {
          return {
            x: xAxis,
            y: secondsToDays(
              tasksChartsData?.accumulatedCompletionPercentilesOnTimeArray[
                index
              ]
            ),
          }
        }) || [],
    },
  ]
  const shouldRenderCompletionTimeEvolutionChart =
    completionTimeEvolutionChartData.some((data) => data.data.length)

  const tasksList = data?.tasksList
  const completionTimeHistogramData = {
    ...tasksList?.completiontimeHistogramChartData,
    values: tasksList?.completiontimeHistogramChartData?.values || [],
    keys:
      tasksList?.completiontimeHistogramChartData?.keys.map(secondsToDays) ||
      [],
  }
  const tasksByTypeData = tasksList?.tasksByType
  const tasksByProjectData = tasksList?.tasksByProject

  const company = me?.currentCompany
  const breadcrumbsLinks = [
    { name: String(company?.name) || "", url: String(company?.slug) },
    { name: t("tasks_chart") },
  ]

  return (
    <TasksList
      filters={taskFilters}
      setFilters={setTaskFilters}
      breadcrumbsLinks={breadcrumbsLinks}
      loading={loading}
      charts
    >
      <Grid container>
        {completionTimeChartData && (
          <ChartGridItem
            title={t("charts.control_completion_time_title")}
            chartTip={t("charts.limitAlert")}
          >
            <ScatterChart
              axisLeftLegend={t("charts.days")}
              data={completionTimeChartData}
              markers={[
                deliveredLeadTimeP65Marker,
                deliveredLeadTimeP80Marker,
                deliveredLeadTimeP95Marker,
              ]}
              onClick={({ xValue }) => {
                const taskExternalID = Number(xValue)
                const taskID = getTaskIDByExternalID(taskExternalID)
                openWindow(`/companies/${companySlug}/tasks/${taskID?.id}`)
              }}
            />
          </ChartGridItem>
        )}

        <ChartGridItem
          title={t("charts.current_partial_completion_title")}
          chartTip={t("charts.limitAlert")}
        >
          <ScatterChart
            axisLeftLegend={t("charts.days")}
            data={partialCompletionTimeChartData}
            markers={[
              deliveredLeadTimeP65Marker,
              deliveredLeadTimeP80Marker,
              deliveredLeadTimeP95Marker,
            ]}
            onClick={({ xValue }) => {
              const taskExternalID = Number(xValue)
              const taskID = getTaskIDByExternalID(taskExternalID)
              openWindow(`/companies/${companySlug}/tasks/${taskID?.id}`)
            }}
          />
        </ChartGridItem>

        <ChartGridItem title={t("charts.flow_data_title")}>
          <BarChart
            axisLeftLegend={t("charts.tasks")}
            data={flowChartData}
            keys={flowChartGroupNames}
            axisBottomLegend={t("charts.flow_data_period_legend")}
            indexBy="key"
            groupMode="grouped"
            tooltip={(data: BarData) => {
              return (
                <BarChartTooltip
                  xLabel={t("charts.flow_data_tooltip_x_legend")}
                  data={data}
                />
              )
            }}
          />
        </ChartGridItem>

        {shouldRenderCompletionTimeEvolutionChart && (
          <ChartGridItem title={t("charts.completion_time_evolution_title")}>
            <LineChart
              axisLeftLegend={t("charts.days")}
              data={completionTimeEvolutionChartData}
              props={{
                margin: { top: 50, right: 60, bottom: 65, left: 60 },
                axisBottom: {
                  legend: t("charts.completion_time_evolution_weeks_legend"),
                  legendOffset: 60,
                  tickRotation: -37,
                  legendPosition: "middle",
                },
                enableSlices: "x",
                sliceTooltip: ({ slice }: SliceTooltipProps) => (
                  <LineChartTooltip
                    slice={slice}
                    xLabel={t(
                      "charts.completion_time_evolution_tooltip_x_legend"
                    )}
                  />
                ),
                legends: [
                  {
                    anchor: "top",
                    direction: "row",
                    toggleSerie: true,
                    justify: false,
                    translateX: 0,
                    translateY: -25,
                    itemsSpacing: 0,
                    itemDirection: "left-to-right",
                    itemWidth: 200,
                    itemHeight: 20,
                    itemOpacity: 0.75,
                    symbolSize: 12,
                    symbolShape: "circle",
                    symbolBorderColor: "rgba(0, 0, 0, .5)",
                    effects: [
                      {
                        on: "hover",
                        style: {
                          itemBackground: "rgba(0, 0, 0, .03)",
                          itemOpacity: 1,
                        },
                      },
                    ],
                  },
                ],
              }}
            />
          </ChartGridItem>
        )}

        {completionTimeHistogramData && (
          <ChartGridItem title={t("charts.completion_time_histogram_chart")}>
            <BarChart
              data={completionTimeHistogramData}
              keys={["value"]}
              indexBy="key"
              axisLeftLegend={t("charts.histogramHits")}
              axisBottomLegend={t("charts.days")}
              padding={0}
            />
          </ChartGridItem>
        )}
        {tasksByTypeData && (
          <ChartGridItem title={t("charts.tasksByType")}>
            <PieChart data={tasksByTypeData} />
          </ChartGridItem>
        )}
        {tasksByProjectData && (
          <ChartGridItem title={t("charts.taksByProject")} columns={12}>
            <BarChart
              data={tasksByProjectData}
              keys={["value"]}
              indexBy="label"
              marginBottom={160}
              marginLeft={160}
              height={640}
            />
          </ChartGridItem>
        )}
      </Grid>
    </TasksList>
  )
}

export default TaskCharts
