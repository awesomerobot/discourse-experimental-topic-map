import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import loadScript from "discourse/lib/load-script";

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

    const chartMin = Math.min(...data.map((item) => item.x));
    const chartMax = Math.max(...data.map((item) => item.x));

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
        responsive: true,

        scales: {
          x: {
            type: "linear",
            position: "bottom",
            min: chartMin,
            max: chartMax,
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
            ticks: {
              stepSize: 1, // whole numbers
              callback: function (value) {
                if (value < 100) {
                  return value;
                } else if (value < 1000) {
                  return Math.round(value / 10) * 10;
                } else if (value < 10000) {
                  return Math.round(value / 100) * 100;
                } else {
                  return Math.round(value / 1000) * 1000;
                }
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
