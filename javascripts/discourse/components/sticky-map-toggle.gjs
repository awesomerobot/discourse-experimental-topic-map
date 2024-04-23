import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import DButton from "discourse/components/d-button";
import i18n from "discourse-common/helpers/i18n";

export default class StickyMapToggle extends Component {
  @service currentUser;
  @service site;
  @service stickyMapState;

  get shouldShow() {
    return settings.topic_map_type !== "static bottom";
  }

  <template>
    {{#if this.shouldShow}}
      <div class="sticky-topic-map-toggle">
        <DButton
          @action={{this.stickyMapState.toggleStickyMap}}
          @icon="receipt"
          @translatedLabel={{i18n (themePrefix "toggle")}}
          class="btn btn-default topic-map-toggle"
        />
      </div>
    {{/if}}
  </template>
}
