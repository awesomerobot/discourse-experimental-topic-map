import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { array, hash } from "@ember/helper";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { inject as service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import { gt } from "truth-helpers";
import AiSummarySkeleton from "discourse/components/ai-summary-skeleton";
import ConditionalLoadingSpinner from "discourse/components/conditional-loading-spinner";
import DButton from "discourse/components/d-button";
import RelativeDate from "discourse/components/relative-date";
import TopicParticipants from "discourse/components/topic-map/topic-participants";
import avatar from "discourse/helpers/bound-avatar-template";
import number from "discourse/helpers/number";
import replaceEmoji from "discourse/helpers/replace-emoji";
import slice from "discourse/helpers/slice";
import { ajax } from "discourse/lib/ajax";
import { emojiUnescape } from "discourse/lib/text";
import dIcon from "discourse-common/helpers/d-icon";
import i18n from "discourse-common/helpers/i18n";
import { avatarImg } from "discourse-common/lib/avatar-utils";
import I18n from "discourse-i18n";
import DTooltip from "float-kit/components/d-tooltip";
import and from "truth-helpers/helpers/and";
import lt from "truth-helpers/helpers/lt";
import not from "truth-helpers/helpers/not";

const TRUNCATED_LINKS_LIMIT = 5;
const MIN_POST_READ_TIME = 4;

export default class SimpleTopicMapSummary extends Component {
  @service siteSettings;

  @tracked mostLikedPosts = [];

  @tracked loading = true;

  get generateSummaryTitle() {
    const title = this.summary.canRegenerate ? "Resummarize" : "Summarize";

    return title;
  }

  get summary() {
    return this.args.topic.get("postStream.topicSummary");
  }

  get generateSummaryIcon() {
    return this.summary.canRegenerate ? "sync" : "discourse-sparkles";
  }

  get linksCount() {
    return this.args.topicDetails.links?.length ?? 0;
  }

  get createdByUsername() {
    return this.args.topicDetails.created_by?.username;
  }

  get lastPosterUsername() {
    return this.args.topicDetails.last_poster?.username;
  }

  get linksToShow() {
    return this.args.topicDetails.links;
  }

  get toggleMapButton() {
    return {
      title: this.args.collapsed
        ? "topic.expand_details"
        : "topic.collapse_details",
      icon: this.args.collapsed ? "chevron-down" : "chevron-up",
      ariaExpanded: this.args.collapsed ? "false" : "true",
      ariaControls: "topic-map-expanded__aria-controls",
      action: this.args.toggleMap,
    };
  }

  get shouldShowParticipants() {
    return (
      this.args.collapsed &&
      this.args.topic.posts_count > 2 &&
      this.args.topicDetails.participants &&
      this.args.topicDetails.participants.length > 0
    );
  }

  get createdByAvatar() {
    return htmlSafe(
      avatarImg({
        avatarTemplate: this.args.topicDetails.created_by?.avatar_template,
        size: "tiny",
        title:
          this.args.topicDetails.created_by?.name ||
          this.args.topicDetails.created_by?.username,
      })
    );
  }

  get lastPostAvatar() {
    return htmlSafe(
      avatarImg({
        avatarTemplate: this.args.topicDetails.last_poster?.avatar_template,
        size: "tiny",
        title:
          this.args.topicDetails.last_poster?.name ||
          this.args.topicDetails.last_poster?.username,
      })
    );
  }

  get readTime() {
    return Math.ceil(
      Math.max(
        this.args.topic.word_count / this.siteSettings.read_time_word_count,
        (this.args.topic.posts_count * 4) / 60
      )
    );
  }

  get topRepliesSummaryEnabled() {
    return this.args.topic.postStream.summary;
  }

  get topRepliesSummaryInfo() {
    if (this.topRepliesSummaryEnabled) {
      return I18n.t("summary.enabled_description");
    }

    const wordCount = this.args.topic.word_count;
    if (wordCount && this.siteSettings.read_time_word_count > 0) {
      const readingTime = Math.ceil(
        Math.max(
          wordCount / this.siteSettings.read_time_word_count,
          (this.args.topic.posts_count * MIN_POST_READ_TIME) / 60
        )
      );
      return I18n.messageFormat("summary.description_time_MF", {
        replyCount: this.args.topic.replyCount,
        readingTime,
      });
    }
    return I18n.t("summary.description", {
      count: this.args.topic.replyCount,
    });
  }

  get topRepliesTitle() {
    if (this.topRepliesSummaryEnabled) {
      return;
    }

    return I18n.t("summary.short_title");
  }

  get topRepliesLabel() {
    const label = this.topRepliesSummaryEnabled ? "All Replies" : "Top Replies";

    return label;
  }

  get topRepliesIcon() {
    if (this.topRepliesSummaryEnabled) {
      return;
    }

    return "layer-group";
  }

  @action
  fetchMostLiked() {
    this.loading = true;
    const filter = `/search.json?q=" " topic%3A${this.args.topic.id} order%3Alikes`;

    ajax(filter)
      .then((data) => {
        data.posts.sort((a, b) => b.like_count - a.like_count);

        this.mostLikedPosts = data.posts.slice(0, 5);
      })
      .catch((error) => {
        // eslint-disable-next-line no-console
        console.error("Error fetching posts:", error);
      })
      .finally(() => {
        this.loading = false;
      });
  }

  @action
  cancelFilter() {
    this.args.topic.postStream.cancelFilter();
    return this.args.topic.postStream.refresh();
  }

  @action
  showTopReplies() {
    return this.args.topic.postStream.showTopReplies();
  }

  <template>
    <ul>
      <li class="created-at">
        <h4 role="presentation">{{i18n "created_lowercase"}}</h4>
        <div class="topic-map-post created-at">
          <a
            class="trigger-user-card"
            data-user-card={{this.createdByUsername}}
            title={{this.createdByUsername}}
            aria-hidden="true"
          />
          {{this.createdByAvatar}}
          <RelativeDate @date={{@topic.created_at}} />
        </div>
      </li>
      <li class="last-reply">
        <a href={{@topic.lastPostUrl}}>
          <h4 role="presentation">{{i18n "last_reply_lowercase"}}</h4>
          <div class="topic-map-post last-reply">
            <a
              class="trigger-user-card"
              data-user-card={{this.lastPosterUsername}}
              title={{this.lastPosterUsername}}
              aria-hidden="true"
            />
            {{this.lastPostAvatar}}
            <RelativeDate @date={{@topic.last_posted_at}} />
          </div>
        </a>
      </li>

      <li class="replies">
        {{number @topic.replyCount noTitle="true"}}
        <h4 role="presentation">{{i18n
            "replies_lowercase"
            count=@topic.replyCount
          }}</h4>
      </li>
      <li class="secondary views">
        {{number @topic.views noTitle="true" class=@topic.viewsHeat}}
        <h4 role="presentation">{{i18n
            "views_lowercase"
            count=@topic.views
          }}</h4>
      </li>

      {{#if (gt @topic.like_count 0)}}
        <DTooltip
          @arrow={{true}}
          @identifier="map-likes"
          @interactive={{true}}
          @triggers="click"
          @placement="right"
        >
          <:trigger>
            {{number @topic.like_count noTitle="true"}}
            <h4 role="presentation">{{i18n
                "likes_lowercase"
                count=@topic.like_count
              }}</h4>
          </:trigger>
          <:content>
            <section class="likes" {{didInsert this.fetchMostLiked}}>
              <h3>Most liked posts</h3>

              <ConditionalLoadingSpinner @condition={{this.loading}}>
                <ul>
                  {{#each this.mostLikedPosts as |post|}}
                    <li>
                      <a
                        href="/t/{{this.args.topic.slug}}/{{this.args.topic.id}}/{{post.post_number}}"
                      >
                        <span class="like-section__user">
                          {{avatar
                            post.avatar_template
                            "tiny"
                            (hash title=post.username)
                          }}
                          {{post.username}}
                        </span>

                        <span class="like-section__likes">
                          {{post.like_count}}
                          {{dIcon "heart"}}</span>
                        <p>
                          {{htmlSafe (emojiUnescape post.blurb)}}
                        </p>
                      </a>
                    </li>
                  {{/each}}
                </ul>
              </ConditionalLoadingSpinner>

            </section>
          </:content>
        </DTooltip>

      {{/if}}

      {{#if (gt this.linksCount 0)}}
        <DTooltip
          @arrow={{true}}
          @identifier="map-links"
          @interactive={{true}}
          @triggers="click"
        >
          <:trigger>

            {{number this.linksCount noTitle="true"}}
            <h4 role="presentation">{{i18n
                "links_lowercase"
                count=this.linksCount
              }}</h4>
          </:trigger>
          <:content>
            <section class="links">
              <h3>{{i18n "topic_map.links_title"}}</h3>
              <table class="topic-links">
                <tbody>
                  {{#each this.linksToShow as |link|}}
                    <tr>
                      <td>
                        <span
                          class="badge badge-notification clicks"
                          title={{i18n "topic_map.clicks" count=link.clicks}}
                        >
                          {{link.clicks}}
                        </span>
                      </td>
                      <td>
                        <TopicMapLink
                          @attachment={{link.attachment}}
                          @title={{link.title}}
                          @rootDomain={{link.root_domain}}
                          @url={{link.url}}
                          @userId={{link.user_id}}
                        />
                      </td>
                    </tr>
                  {{/each}}
                </tbody>
              </table>
              {{#if
                (and
                  (not this.allLinksShown)
                  (lt TRUNCATED_LINKS_LIMIT this.topicLinks.length)
                )
              }}
                <div class="link-summary">
                  <span>
                    <DButton
                      @action={{this.showAllLinks}}
                      @title="topic_map.links_shown"
                      @icon="chevron-down"
                      class="btn-flat"
                    />
                  </span>
                </div>
              {{/if}}
            </section>
          </:content>
        </DTooltip>
      {{/if}}
      {{#if (and (gt @topic.participant_count 5) this.shouldShowParticipants)}}
        <DTooltip
          @arrow={{true}}
          @identifier="map-users"
          @interactive={{true}}
          @triggers="click"
          @inline={{true}}
          @placement="right"
        >
          <:trigger>
            {{number @topic.participant_count noTitle="true"}}
            <h4 role="presentation">{{i18n
                "users_lowercase"
                count=@topic.participant_count
              }}</h4>
          </:trigger>
          <:content>
            <section class="avatars">
              <TopicParticipants
                @title={{i18n "topic_map.participants_title"}}
                @userFilters={{@userFilters}}
                @participants={{@topicDetails.participants}}
              />
            </section>

          </:content>
        </DTooltip>

      {{/if}}

      {{#if this.shouldShowParticipants}}
        <li class="avatars">
          <TopicParticipants
            @participants={{slice 0 5 @topicDetails.participants}}
            @userFilters={{@userFilters}}
          />
        </li>
      {{/if}}
      <div class="map-buttons">
        <div class="estimated-read-time">
          <span> read </span>
          <span>
            {{this.readTime}}
            min
          </span>
        </div>
        <div class="summarization-buttons">
          {{#if @topic.summarizable}}
            <DTooltip
              @onShow={{@showSummary}}
              @identifier="map-summary"
              @placement="left"
              @triggers="click"
            >
              <:trigger>
                <DButton
                  @translatedLabel={{this.generateSummaryTitle}}
                  @translatedTitle={{this.generateSummaryTitle}}
                  @icon={{this.generateSummaryIcon}}
                  @disabled={{this.summary.loading}}
                  class="btn-default topic-strategy-summarization"
                />
              </:trigger>
              <:content>
                <div class="topic-map">
                  <div class="toggle-summary">
                    {{#if this.summary.showSummaryBox}}
                      <article class="summary-box">
                        {{#if (not this.summary.text)}}
                          <AiSummarySkeleton />
                        {{else}}
                          <div
                            class="generated-summary"
                          >{{this.summary.text}}</div>

                          {{#if this.summary.summarizedOn}}
                            <div class="summarized-on">
                              <p>
                                {{i18n
                                  "summary.summarized_on"
                                  date=this.summary.summarizedOn
                                }}

                                <DTooltip @placements={{array "top-end"}}>
                                  <:trigger>
                                    {{dIcon "info-circle"}}
                                  </:trigger>
                                  <:content>
                                    {{i18n
                                      "summary.model_used"
                                      model=this.summary.summarizedBy
                                    }}
                                  </:content>
                                </DTooltip>
                              </p>

                              {{#if this.summary.outdated}}
                                <p class="outdated-summary">
                                  {{this.outdatedSummaryWarningText}}
                                </p>
                              {{/if}}
                            </div>
                          {{/if}}
                        {{/if}}
                      </article>
                    {{/if}}
                  </div>
                </div>
              </:content>

            </DTooltip>

          {{/if}}
          {{#if @topic.has_summary}}

            <DButton
              @action={{if
                @topic.postStream.summary
                this.cancelFilter
                this.showTopReplies
              }}
              @translatedTitle={{this.topRepliesTitle}}
              @translatedLabel={{this.topRepliesLabel}}
              @icon={{this.topRepliesIcon}}
              class="top-replies"
            />
          {{/if}}
        </div>
      </div>

    </ul>
  </template>
}

class TopicMapLink extends Component {
  get linkClasses() {
    return this.args.attachment
      ? "topic-link track-link attachment"
      : "topic-link track-link";
  }

  get truncatedContent() {
    const truncateLength = 85;
    const content = this.args.title || this.args.url;
    return content.length > truncateLength
      ? `${content.slice(0, truncateLength).trim()}...`
      : content;
  }

  <template>
    <a
      class={{this.linkClasses}}
      href={{@url}}
      title={{@url}}
      data-user-id={{@userId}}
      data-ignore-post-id="true"
      target="_blank"
      rel="nofollow ugc noopener noreferrer"
    >
      {{#if @title}}
        {{replaceEmoji this.truncatedContent}}
      {{else}}
        {{this.truncatedContent}}
      {{/if}}
    </a>
    {{#if (and @title @rootDomain)}}
      <span class="domain">
        {{@rootDomain}}
      </span>
    {{/if}}
  </template>
}
