# frozen_string_literal: true

module Demandable
  extend ActiveSupport::Concern

  def average_queue_time
    total_queue_time = demands.kept.sum(&:total_queue_time)
    total_demands = demands.kept.count

    return 0 if total_queue_time.zero? || total_demands.zero?

    total_queue_time.to_f / total_demands
  end

  def average_touch_time
    total_touch_time = demands.kept.sum(&:total_touch_time)
    total_demands = demands.kept.count

    return 0 if total_touch_time.zero? || total_demands.zero?

    total_touch_time.to_f / total_demands
  end

  def avg_hours_per_demand
    return 0 unless demands.kept.count.positive?

    demands.kept.filter_map(&:total_effort).sum / demands.kept.count
  end

  def upstream_demands(limit_date = Time.zone.now)
    demands.not_discarded_until(limit_date).not_committed(limit_date) - demands.not_discarded_until(limit_date).not_started(limit_date)
  end

  ##
  # This method returns the relation between concluded and not concluded demands
  def percentage_concluded
    demands_kept = demands.kept
    finished = demands_kept.finished_until_date(Time.zone.now).count

    demands_count = demands_kept.count

    return 0 if demands_count.zero? || finished.zero?

    finished / demands_count.to_f
  end

  ##
  # This method returns the percentage of demands with lead time above the demand informed as argument
  # It will return based on everything regardless the type and class of service
  def lead_time_position_percentage(demand)
    demands_without_tested_demand = demands.kept.where.not(id: demand.id)
    return 0 if demands_without_tested_demand.blank?

    compute_demand_lead_time_position(demands_without_tested_demand, demand)
  end

  ##
  # This method returns the percentage of demands, within the same type, with lead time above the demand informed as argument
  # It will return based on the informed demand type
  def lead_time_position_percentage_same_type(demand)
    demands_without_tested_demand = demands.where(work_item_type: demand.work_item_type).kept.where.not(id: demand.id)
    return 0 if demands_without_tested_demand.blank?

    compute_demand_lead_time_position(demands_without_tested_demand, demand)
  end

  ##
  # This method returns the percentage of demands, within the same class of service, with lead time above the demand informed as argument
  # It will return based on the informed demand class of service
  def lead_time_position_percentage_same_cos(demand)
    demands_without_tested_demand = demands.where(class_of_service: demand.class_of_service).kept.where.not(id: demand.id)
    return 0 if demands_without_tested_demand.blank?

    compute_demand_lead_time_position(demands_without_tested_demand, demand)
  end

  def lead_time_breakdown
    DemandService.instance.lead_time_breakdown(demands)
  end

  def general_leadtime(percentile = 80)
    Stats::StatisticsService.instance.percentile(percentile, demands.finished_until_date(Time.zone.now).map(&:leadtime))
  end

  private

  def compute_demand_lead_time_position(demands, demand)
    worse_lead_times_count = demands.where('leadtime > :lead_time_limit', lead_time_limit: demand.leadtime).kept.count

    worse_lead_times_count.to_f / demands.kept.finished_with_leadtime.count
  end
end
