import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import loadScript from "discourse/lib/load-script";

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

export default class TopicViewsChart extends Component {
  @tracked chart = null;

  @action
  async renderChart(element) {
    await loadScript("/javascripts/Chart.min.js");

    const data = this.args.views.stats.map((item) => ({
      x: new Date(`${item.viewed_at}T00:00:00`).getTime(),
      y: item.views,
    }));

    const context = element.getContext("2d");

    let showLine = true;

    // if there's only one point, center and hide the line
    if (data.length === 1) {
      showLine = false;
      const singleDataPoint = data[0];
      const bufferBefore = {
        x: singleDataPoint.x - 86400000,
      };
      const bufferAfter = {
        x: singleDataPoint.x + 86400000,
      };
      data.unshift(bufferBefore);
      data.push(bufferAfter);
    }

    const xMin = Math.min(...data.map((item) => item.x));
    const xMax = Math.max(...data.map((item) => item.x));

    const filteredData = data.filter((item) => item.y !== undefined);
    const yMax = Math.max(...filteredData.map((item) => item.y));

    const topicMapElement = document.querySelector(".revamped-topic-map");

    const lineColor =
      getComputedStyle(topicMapElement).getPropertyValue("--chart-line-color");
    const pointColor = getComputedStyle(topicMapElement).getPropertyValue(
      "--chart-point-color"
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
            data,
            showLine,
            borderColor: pointColor,
            backgroundColor: lineColor,
            pointBackgroundColor: pointColor,
            pointRadius: 3,
            borderWidth: 2,
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
              autoSkip: true,
              maxTicksLimit: data.length,
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
            suggestedMax: yMax,
            ticks: {
              stepSize: calculateAdjustedStepSize(filteredData),
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
                return `Views: ${tooltipItem?.parsed?.y}`;
              },
            },
          },
        },
      },
    });
  }

  <template>
    <canvas {{didInsert this.renderChart}}></canvas>
  </template>
}
