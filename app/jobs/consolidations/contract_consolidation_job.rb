# frozen_string_literal: true

module Consolidations
  class ContractConsolidationJob < ApplicationJob
    queue_as :low

    def perform(contract)
      contract_start = contract.start_date
      start_date = contract.start_date
      end_date = [contract.end_date, Time.zone.today.end_of_month].min

      while start_date <= end_date
        end_of_month = start_date.end_of_month

        demands = contract.demands.opened_before_date(end_of_month)

        if demands.present?
          demands_chart_adapter = Highchart::DemandsChartsAdapter.new(demands, contract_start, end_of_month, 'week')

          contract_based_montecarlo_durations = Stats::StatisticsService.instance.run_montecarlo(contract.remaining_work(end_of_month), demands_chart_adapter.throughput_chart_data.last(20), 500)
          risk_to_date = 1 - Stats::StatisticsService.instance.compute_odds_to_deadline(contract.remaining_weeks(end_of_month), contract_based_montecarlo_durations)

          demands_finished = contract.demands.kept.finished_after_date(contract_start).finished_until_date(start_date)
          real_hours_per_demand = if demands_finished.count.positive?
                                    demands_finished.map(&:total_effort).compact.sum / demands_finished.count
                                  else
                                    0
                                  end

          consolidation = Consolidations::ContractConsolidation.find_or_initialize_by(contract: contract, consolidation_date: end_of_month)
          consolidation.update(operational_risk_value: risk_to_date,
                               min_monte_carlo_weeks: contract_based_montecarlo_durations.min || 0,
                               max_monte_carlo_weeks: contract_based_montecarlo_durations.max || 0,
                               monte_carlo_duration_p80_weeks: Stats::StatisticsService.instance.percentile(80, contract_based_montecarlo_durations) || 0,
                               real_hours_per_demand: real_hours_per_demand,
                               estimated_hours_per_demand: contract.hours_per_demand_to_date(start_date))
        else
          consolidation = Consolidations::ContractConsolidation.find_or_initialize_by(contract: contract, consolidation_date: end_of_month)
          consolidation.update(operational_risk_value: 1,
                               min_monte_carlo_weeks: 0,
                               max_monte_carlo_weeks: 0,
                               monte_carlo_duration_p80_weeks: 0,
                               real_hours_per_demand: 0,
                               estimated_hours_per_demand: contract.hours_per_demand_to_date(start_date))
        end

        start_date += 1.month
      end
    end
  end
end
