// Set environment
// GOOGLE_CLOUD_PROJECT, GOOGLE_APPLICATION_CREDENTIALS
package isuports

import (
	"log"
	"net/http"
	"os"

	"cloud.google.com/go/profiler"
	"contrib.go.opencensus.io/exporter/stackdriver"
	"contrib.go.opencensus.io/integrations/ocsql"
	"go.opencensus.io/plugin/ochttp"
	"go.opencensus.io/trace"
)

func initProfiler() {
	// TODO: この辺の設定方法考える
	if err := profiler.Start(profiler.Config{
		Service:        "isucon-20210717",
		ServiceVersion: "1.0.2",
		ProjectID:      os.Getenv("GOOGLE_CLOUD_PROJECT"),
	}); err != nil {
		log.Fatal(err)
	}
}

func initTrace() {
	exporter, err := stackdriver.NewExporter(stackdriver.Options{
		ProjectID:                os.Getenv("GOOGLE_CLOUD_PROJECT"),
		TraceSpansBufferMaxBytes: 32 * 1024 * 1024,
	})
	if err != nil {
		log.Fatal(err)
	}
	trace.RegisterExporter(exporter)

	trace.ApplyConfig(trace.Config{DefaultSampler: trace.ProbabilitySampler(0.05)})
}

func withTrace(h http.Handler) http.Handler {
	return &ochttp.Handler{Handler: h}
}

// traceDriver create trace for databse
//
// Example
//   db, _ := sql.Open(traceDriver("mysql"), dns)
//   dbx := sqlx.NewDb(db, "mysql")
func tracedDriver(driverName string) string {
	driverName, err := ocsql.Register(driverName, ocsql.WithQuery(true), ocsql.WithQueryParams(true))
	if err != nil {
		log.Fatal(err)
	}
	return driverName
}
