import Component from "@glimmer/component";

export default class SimpleViewCounts extends Component {
  adjustAggregatedData(stats) {
    const adjustedStats = [];

    stats.forEach((stat) => {
      const localDate = new Date(`${stat.viewed_at}T00:00:00Z`);
      const localDateStr = localDate.toLocaleDateString(undefined, {
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
      });

      const existingStat = adjustedStats.find(
        (s) => s.dateStr === localDateStr
      );

      if (existingStat) {
        existingStat.views += stat.views;
      } else {
        adjustedStats.push({
          dateStr: localDateStr,
          views: stat.views,
          localDate,
        });
      }
    });

    return adjustedStats.map((stat) => ({
      viewed_at: stat.localDate.toISOString().split("T")[0],
      views: stat.views,
    }));
  }

  get updatedStats() {
    const adjustedStats = this.adjustAggregatedData(this.args.views.stats);

    let stats = adjustedStats.map((stat) => {
      const statDate = new Date(`${stat.viewed_at}T00:00:00`).getTime();
      const localStatDate = new Date(statDate);

      return {
        ...stat,
        statDate: localStatDate,
        label: this.formatDate(localStatDate),
      };
    });

    return stats;
  }

  formatDate(date) {
    return date.toLocaleDateString(undefined, {
      month: "2-digit",
      day: "2-digit",
    });
  }

  <template>
    <div class="simple-view-count__wrapper">
      {{#each this.updatedStats as |stat|}}
        <div class="simple-view-count">
          <div class="simple-view-count__views">
            {{stat.views}}
          </div>
          <div class="simple-view-count__date">
            {{stat.label}}
          </div>
        </div>
      {{/each}}
    </div>
  </template>
}
