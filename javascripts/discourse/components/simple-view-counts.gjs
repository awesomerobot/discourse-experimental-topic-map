import Component from "@glimmer/component";
import { eq } from "truth-helpers";
import i18n from "discourse-common/helpers/i18n";

export default class SimpleViewCounts extends Component {
  get updatedStats() {
    let stats = this.args.views.stats.map((stat, index, array) => {
      let label = null;

      const today = new Date().setHours(0, 0, 0, 0);
      const yesterday = new Date(today - 86400000).setHours(0, 0, 0, 0);
      const statDate = new Date(`${stat.viewed_at}T00:00:00`).setHours(
        0,
        0,
        0,
        0
      );

      if (array.length === 1 || statDate === today) {
        label = "today";
      } else if (statDate === yesterday) {
        label = "yesterday";
      }

      return {
        ...stat,
        label: label || this.formatDate(stat.viewed_at),
      };
    });

    return stats;
  }

  formatDate(date) {
    const day = new Date(date);
    return day.toLocaleDateString(undefined, {
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
            {{#if (eq stat.label "today")}}
              {{i18n (themePrefix "today")}}
              <span class="simple-view-count__so-far">
                {{i18n (themePrefix "so_far")}}
              </span>
            {{else if (eq stat.label "yesterday")}}
              {{i18n (themePrefix "yesterday")}}
            {{else}}
              {{stat.label}}
            {{/if}}
          </div>
        </div>
      {{/each}}
    </div>
  </template>
}
