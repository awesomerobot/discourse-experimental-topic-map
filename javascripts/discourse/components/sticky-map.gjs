import Component from "@glimmer/component";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { inject as service } from "@ember/service";
import SummaryBox from "discourse/components/summary-box";
import TopicMap from "discourse/components/topic-map";
import or from "truth-helpers/helpers/or";
import SimpleTopicMapSummary from "../components/simple-topic-map-summary";

export default class StickyMap extends Component {
  @service currentUser;
  @service site;
  @service stickyMapState;

  observer = null;

  willDestroyElement() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  get topicDetails() {
    return this.args.outletArgs.model.get("details");
  }

  get simplifiedMap() {
    return settings.simplified_map;
  }

  @action
  showSummary() {
    return this.args.outletArgs.model.postStream.showSummary();
  }

  @action
  showTopReplies() {
    return this.args.outletArgs.model.postStream.showTopReplies();
  }

  @action
  collapseSummary() {
    return this.args.outletArgs.model.postStream.collapseSummary();
  }

  @action
  cancelFilter() {
    return this.args.outletArgs.model.postStream.cancelFilter();
  }

  @action
  updateCurrentPost() {
    return this.stickyMapState.updateCurrentPost(
      this.args.outletArgs.model.currentPost
    );
  }

  @action
  observeStickyMap() {
    if (settings.topic_map_type !== "sticky bottom") {
      return;
    }

    // controls shadow by detecting when the element is sticky

    const el = document.querySelector(".sticky-topic-map");

    this.observer = new IntersectionObserver(
      ([entry]) => {
        const isSticky = entry.intersectionRatio < 1;
        entry.target.classList.toggle("is-sticky", isSticky);
      },
      {
        threshold: [1],
        rootMargin: "0px 0px -1px 0px",
      }
    );

    this.observer.observe(el);
  }

  @action
  observeSummaryClick(element) {
    const handleClick = (event) => {
      const button = event.target.closest("button");

      if (button && button.closest(".summarization-buttons")) {
        this.stickyMapState.updateCurrentTab(null);
      }

      if (event.target.closest(".secondary")) {
        this.collapseSummary();
      }
    };

    element.addEventListener("click", handleClick, true);

    this.cleanup = () => {
      element.removeEventListener("click", handleClick, true);
    };
  }

  willDestroy() {
    super.willDestroy();
    if (this.cleanup) {
      this.cleanup();
    }
  }

  <template>
    {{#if this.stickyMapState.stickyMapVisible}}
      {{#unless @outletArgs.model.postStream.loadingFilter}}
        <div
          class="sticky-topic-map"
          {{didUpdate
            this.updateCurrentPost
            this.args.outletArgs.model.currentPost
          }}
          {{didInsert this.observeStickyMap}}
        >

          {{#if this.simplifiedMap}}
            <div
              class="topic-map --simplified"
              {{didInsert this.observeSummaryClick}}
            >
              <div class="map">
                <SimpleTopicMapSummary
                  @topic={{@outletArgs.model}}
                  @topicDetails={{this.topicDetails}}
                  @collapsed={{true}}
                />

                {{#if
                  (or
                    @outletArgs.model.has_summary @outletArgs.model.summarizable
                  )
                }}
                  <section class="information toggle-summary">
                    <SummaryBox
                      @topic={{@outletArgs.model}}
                      @postStream={{@outletArgs.model.postStream}}
                      @showTopReplies={{this.showTopReplies}}
                      @collapseSummary={{this.collapseSummary}}
                      @showSummary={{this.showSummary}}
                    />
                  </section>
                {{/if}}
              </div>
            </div>
          {{else}}
            <div class="topic-map">
              <TopicMap
                @model={{@outletArgs.model}}
                @postStream={{@outletArgs.model.postStream}}
                @cancelFilter={{this.cancelFilter}}
                @showTopReplies={{this.showTopReplies}}
                @showSummary={{this.showSummary}}
                @topicDetails={{@outletArgs.model.details}}
                @collapseSummary={{this.collapseSummary}}
              />
            </div>
          {{/if}}
        </div>
      {{/unless}}
    {{/if}}
  </template>
}
