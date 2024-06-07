import Component from "@glimmer/component";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import loadScript from "discourse/lib/load-script";
import i18n from "discourse-common/helpers/i18n";

const now = new Date();
const startOfDay = new Date(now.setHours(0, 0, 0, 0)).getTime();
const oneDay = 86400000;

function calculateAdjustedStepSize(data) {
  const range =
    Math.max(...data.map((item) => item.y)) -
    Math.min(...data.map((item) => item.y));

  if (range < 5) {
    return 1;
  }

  const stepSize = range / 5;
  const magnitude = Math.pow(10, Math.floor(Math.log10(stepSize)));
  return Math.ceil(stepSize / magnitude) * magnitude;
}

function fillMissingDates(data) {
  const filledData = [];
  let currentDate = new Date(data[0].x);

  for (let i = 0; i < data.length; i++) {
    while (currentDate.getTime() < data[i].x) {
      filledData.push({ x: currentDate.getTime(), y: 0 });
      currentDate = new Date(currentDate.getTime() + oneDay);
    }
    filledData.push(data[i]);
    currentDate = new Date(currentDate.getTime() + oneDay);
  }

  return filledData;
}

function predictTodaysViews(data) {
  const totalViews = data.reduce((acc, item) => acc + item.y, 0);
  const averageViews = totalViews / data.length;
  const elapsedTime = (Date.now() - startOfDay) / oneDay;
  const currentViews = data[data.length - 1].y; // partial data for today

  const predictedViews = Math.round(
    currentViews + averageViews * (1 - elapsedTime)
  );

  return Math.max(predictedViews, currentViews); // never lower than actual data
}

export default class TopicViewsChart extends Component {
  chart = null;
  noData = false;

  @action
  async renderChart(element) {
    await loadScript("/javascripts/Chart.min.js");

    if (!this.args.views?.stats || this.args.views?.stats?.length === 0) {
      return (this.noData = true);
    }

    let data = this.args.views.stats.map((item) => ({
      x: new Date(`${item.viewed_at}T00:00:00`).getTime(),
      y: item.views,
    }));

    data = fillMissingDates(data);

    const todayData = data.find((item) => item.x === startOfDay);
    const currentViews = todayData ? todayData.y : 0;
    // remove current day's actual point, we'll replace with prediction
    data = data.filter((item) => item.x !== startOfDay);
    const today = new Date().setHours(0, 0, 0, 0);

    const predictedViews = predictTodaysViews(data);
    const predictedDataPoint = {
      x: now.getTime(),
      y: Math.max(predictedViews, currentViews),
    };

    data.push(predictedDataPoint);

    let showLine = true;

    const context = element.getContext("2d");

    const xMin = Math.min(...data.map((item) => item.x));
    const xMax = Math.max(...data.map((item) => item.x));

    const topicMapElement = document.querySelector(".revamped-topic-map");

    // grab colors from CSS
    const lineColor =
      getComputedStyle(topicMapElement).getPropertyValue("--chart-line-color");
    const pointColor = getComputedStyle(topicMapElement).getPropertyValue(
      "--chart-point-color"
    );
    const predictionColor = getComputedStyle(topicMapElement).getPropertyValue(
      "--chart-prediction-color"
    );

    if (this.chart) {
      this.chart.destroy();
    }

    this.chart = new window.Chart(context, {
      type: "line",
      data: {
        datasets: [
          {
            label: "Views",
            data: data.slice(0, -1),
            showLine,
            borderColor: pointColor,
            backgroundColor: lineColor,
            pointBackgroundColor: pointColor,
          },
          {
            label: "Predicted Views",
            data: [data[data.length - 2], predictedDataPoint],
            showLine: true,
            borderDash: [5, 5],
            borderColor: predictionColor,
            backgroundColor: predictionColor,
            pointBackgroundColor: predictionColor,
          },
        ],
      },
      options: {
        scales: {
          x: {
            type: "linear",
            position: "bottom",
            min: xMin,
            max: xMax,
            ticks: {
              autoSkip: false,
              stepSize: 86400000,
              maxTicksLimit: 15,
              callback: function (value) {
                const date = new Date(value);
                return date.toLocaleDateString(undefined, {
                  month: "2-digit",
                  day: "2-digit",
                });
              },
            },
          },
          y: {
            beginAtZero: true,
            ticks: {
              stepSize: calculateAdjustedStepSize(data),
              callback: function (value) {
                return value;
              },
            },
          },
        },
        plugins: {
          legend: {
            display: false,
          },
          tooltip: {
            callbacks: {
              title: function (tooltipItem) {
                const date = new Date(tooltipItem[0]?.parsed?.x);
                return date.toLocaleDateString(undefined, {
                  month: "2-digit",
                  day: "2-digit",
                  year: "numeric",
                });
              },
              label: function (tooltipItem) {
                if (tooltipItem.datasetIndex === 1 && startOfDay === today) {
                  return `Predicted Views: ${tooltipItem?.parsed?.y}`;
                } else if (tooltipItem.datasetIndex === 0) {
                  return `Views: ${tooltipItem?.parsed?.y}`;
                }
                return null;
              },
            },
            filter: function (tooltipItem) {
              const date = new Date(tooltipItem?.parsed?.x).setHours(
                0,
                0,
                0,
                0
              );

              // show predicted data point only for today, not past
              return (
                tooltipItem.datasetIndex === 0 ||
                (tooltipItem.datasetIndex === 1 && date === today)
              );
            },
          },
        },
      },
    });
  }

  <template>
    {{#if this.noData}}
      {{i18n (themePrefix "chart_error")}}
    {{else}}
      <canvas {{didInsert this.renderChart}}></canvas>
      <div class="view-explainer">{{i18n (themePrefix "view_explainer")}}</div>
    {{/if}}
  </template>
}
