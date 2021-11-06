"""Application exporter"""
# ref https://trstringer.com/quick-and-easy-prometheus-exporter/
import os
import time
from prometheus_client import start_http_server, Gauge, Enum
from ws import emhi_xml
metrics = {
            "airtemperature": ["Gauge","Current air temperature"],
            "airpressure": ["Gauge","Current air pressure"],
            "precipitations": ["Gauge","Current precipitations"],
            "relativehumidity": ["Gauge","Current relative humidity"],
            "uvindex": ["Gauge","Current UV Index"],
            "visibility": ["Gauge","Current visibility"],
            "winddirection": ["Gauge","Wind direction"],
            "windspeed": ["Gauge","Current wind speed"],
            "windspeedmax": ["Gauge","Wind gust"],
            }

class AppMetrics:
    """
    Representation of Prometheus metrics and loop to fetch and transform
    application metrics into Prometheus metrics.
    """

    def __init__(self, polling_interval_seconds=60):
        self.polling_interval_seconds = polling_interval_seconds
        self.gauge = Gauge('ws_metrics', 'Weather station metrics', ['name', 'location','desc'])

    def run_metrics_loop(self):
        """Metrics fetching loop"""

        while True:
            self.fetch()
            time.sleep(self.polling_interval_seconds)

    def fetch(self):
        """
        Get metrics from application and refresh Prometheus metrics with
        new values.
        """

        # Fetch raw status data from the application
        # weather_station = os.getenv("EMHI_STATION", "Tallinn-Harku")
        ws_data = emhi_xml(weather_station)
        for ws in ws_data:
            weather_station = ws['name']
            for key, value in ws.items():
                if weather_station == value:
                    continue
                value=ws_data.get(key,0)
                self.gauge.labels(key, weather_station, desc[1]).set(value)
                print(f"{weather_station},{key}={value}=>{desc[1]}")

def main():
    """Main entry point"""
    print("Starting WS Poller")
    polling_interval_seconds = int(os.getenv("POLLING_INTERVAL_SECONDS", "60"))
    exporter_port = int(os.getenv("EXPORTER_PORT", "9877"))

    app_metrics = AppMetrics(
        polling_interval_seconds=polling_interval_seconds
    )
    start_http_server(exporter_port)
    app_metrics.run_metrics_loop()

if __name__ == "__main__":
    main()