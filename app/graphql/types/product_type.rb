# frozen_string_literal: true

module Types
  class ProductType < Types::BaseObject
    field :company, Types::CompanyType, null: true
    field :id, ID, null: false
    field :latest_deliveries, [Types::DemandType], null: true
    field :name, String, null: false
    field :slug, String, null: false

    field :average_queue_time, Integer, null: true
    field :average_speed, Float, null: true
    field :average_touch_time, Integer, null: true
    field :created_demands_count, Integer, null: true
    field :delivered_demands_count, Integer, null: true
    field :demands_blocks_count, Integer, null: true
    field :discarded_demands_count, Integer, null: true
    field :downstream_demands_count, Integer, null: true
    field :leadtime_p65, Integer, null: true
    field :leadtime_p80, Integer, null: true
    field :leadtime_p95, Integer, null: true
    field :portfolio_units_count, Integer, null: true
    field :remaining_backlog_count, Integer, null: true
    field :unscored_demands_count, Integer, null: true
    field :upstream_demands_count, Integer, null: true

    field :leadtime_evolution_data, Types::Charts::LeadtimeEvolutionType, null: true

    def latest_deliveries
      finished_demands.order(end_date: :desc).limit(15)
    end

    def created_demands_count
      object.demands.kept.opened_before_date(Time.zone.now).count
    end

    def delivered_demands_count
      finished_demands.count
    end

    def upstream_demands_count
      object.upstream_demands.count
    end

    def downstream_demands_count
      object.demands.kept.in_wip(Time.zone.now).count
    end

    def discarded_demands_count
      object.demands.discarded.count
    end

    def unscored_demands_count
      object.demands.kept.unscored_demands.count
    end

    def demands_blocks_count
      object.demand_blocks.kept.count
    end

    def portfolio_units_count
      object.portfolio_units.count
    end

    def average_speed
      DemandService.instance.average_speed(finished_demands)
    end

    def leadtime_p95
      object.general_leadtime(95)
    end

    def leadtime_p80
      object.general_leadtime
    end

    def leadtime_p65
      object.general_leadtime(65)
    end

    def leadtime_evolution_data
      demands_charts_adapter = Highchart::DemandsChartsAdapter.new(object.demands.kept, object.start_date, object.end_date, 'month')

      leadtime_evolution = demands_charts_adapter.leadtime_percentiles_on_time_chart_data

      { x_axis: demands_charts_adapter.x_axis.map(&:to_s), y_axis_in_month: leadtime_evolution[:y_axis][0][:data], y_axis_accumulated: leadtime_evolution[:y_axis][1][:data] }
    end

    private

    def finished_demands
      @finished_demands ||= object.demands.kept.finished_until_date(Time.zone.now)
    end
  end
end
