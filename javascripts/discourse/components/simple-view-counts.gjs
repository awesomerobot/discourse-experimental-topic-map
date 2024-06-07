import Component from "@glimmer/component";
import { eq } from "truth-helpers";
import i18n from "discourse-common/helpers/i18n";

export default class SimpleViewCounts extends Component {
  get updatedStats() {
    let stats = this.args.views.stats.map((stat, index, array) => {
      return {
        ...stat,
        label:
          array.length === 1 || index === array.length - 1
            ? "today"
            : index === array.length - 2
            ? "yesterday"
            : null,
      };
    });

    return stats;
  }

  <template>
    <div class="simple-view-count__wrapper">
      {{#each this.updatedStats as |stat|}}
        <div class="simple-view-count">
          <div class="simple-view-count__views">
            {{stat.views}}
          </div>
          <div class="simple-view-count__date">
            {{i18n (themePrefix stat.label)}}
            <span class="simple-view-count__so-far">
              {{#if stat.label}}
                {{#if (eq stat.label "today")}}
                  {{i18n (themePrefix "so_far")}}
                {{/if}}
              {{/if}}
            </span>
          </div>
        </div>
      {{/each}}
    </div>
  </template>
}
