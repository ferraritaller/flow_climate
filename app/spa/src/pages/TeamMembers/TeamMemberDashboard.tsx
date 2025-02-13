import { useContext } from "react"
import { useTranslation } from "react-i18next"
import { gql, useQuery } from "@apollo/client"
import { useParams } from "react-router-dom"

import { MeContext } from "../../contexts/MeContext"
import BasicPage from "../../components/BasicPage"
import { TeamMember } from "../../modules/teamMember/teamMember.types"
import TeamMemberDashboardTables from "../../components/TeamMemberDashboardTables"
import TeamMemberDashboardCharts from "../../components/TeamMemberDashboardCharts"

const TEAM_MEMBER_QUERY = gql`
  query TeamMember($id: Int!) {
    teamMember(id: $id) {
      id
      name
      startDate
      endDate
      deliveredDemands: demands(status: DELIVERED_DEMANDS) {
        id
      }
      bugs: demands(status: DELIVERED_DEMANDS, type: "BUG") {
        id
      }
      demandShortestLeadTime {
        id
        leadtime
      }
      demandLargestLeadTime {
        id
        leadtime
      }
      leadTimeHistogramChartData {
        keys
        values
      }
      leadTimeControlChartData {
        xAxis
        leadTimes
        leadTimeP65
        leadTimeP80
        leadTimeP95
      }
      memberEffortData {
        xAxis
        yAxis
      }
      memberEffortDailyData {
        xAxis
        yAxis
      }
      demandLeadTimeP80
      memberThroughputData(numberOfWeeks: 24)
      averagePullIntervalData {
        xAxis
        yAxis
      }
      projectHoursData {
        xAxis
        yAxisHours
        yAxisProjectsNames
      }
      projectsList(orderField: "end_date", sortDirection: DESC) {
        totalCount
        projects {
          id
          name
          startDate
          endDate
          currentRiskToDeadline
          leadTimeP80
          company {
            id
            slug
          }
        }
      }
      teams {
        id
        name
        company {
          slug
        }
      }
      demandBlocksList(
        orderField: "block_time"
        sortDirection: DESC
        perPage: 6
      ) {
        demandBlocks {
          id
          demand {
            id
            demandTitle
          }
          blockTime
          unblockTime
        }
      }
      latestDeliveries: demands(status: DELIVERED_DEMANDS, limit: 10) {
        id
        project {
          id
          name
        }
        product {
          id
          name
        }
        externalId
        endDate
        leadtime
        company {
          id
          slug
        }
      }
    }
  }
`

type TeamMemberDTO = {
  teamMember: TeamMember
}

const TeamMemberDashboard = () => {
  const { t } = useTranslation(["teamMembers"])
  const { me } = useContext(MeContext)
  const { teamMemberId } = useParams()
  const { data, loading } = useQuery<TeamMemberDTO>(TEAM_MEMBER_QUERY, {
    variables: {
      id: Number(teamMemberId),
    },
  })
  const companySlug = me?.currentCompany?.slug
  const companyUrl = `/companies/${companySlug}`
  const teamMemberName = data?.teamMember?.name || ""
  const breadcrumbsLinks = [
    { name: me?.currentCompany?.name || "", url: companyUrl },
    {
      name: t("list.title"),
      url: `${companyUrl}/team_members`,
    },
    {
      name: teamMemberName,
    },
  ]

  const teamMember = data?.teamMember

  return (
    <BasicPage
      breadcrumbsLinks={breadcrumbsLinks}
      title={teamMemberName}
      loading={loading}
    >
      {teamMember && (
        <>
          <TeamMemberDashboardTables teamMember={teamMember} />
          <TeamMemberDashboardCharts teamMember={teamMember} />
        </>
      )}
    </BasicPage>
  )
}

export default TeamMemberDashboard
