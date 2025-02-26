package main

import (
	log "github.com/sirupsen/logrus"
	"github.com/gorilla/mux"
	"net/http"
	"time"
	"os"
)

var router = mux.NewRouter()

func write_error(w http.ResponseWriter) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	jsonData := []byte(`{"status":"ERROR","reason":"bad request"}`)
	w.Write(jsonData)
}

func write_error_message(w http.ResponseWriter, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	jsonData := []byte(`{"status":"ERROR","reason":"` + message + `"}`)
	w.Write(jsonData)
}

func main() {
	log_level := os.Getenv("LOG_LEVEL")

	if log_level == "DEBUG" {
		log.SetLevel(log.DebugLevel)
		log.Info("bolt card service started - debug log level")
	} else {
		log.Info("bolt card service started - production log level")
	}

	log.SetFormatter(&log.JSONFormatter{
		DisableHTMLEscape: true,
	})

// createboltcard
	router.Path("/new").Methods("GET").HandlerFunc(new_card_request)
// lnurlw for pos
	router.Path("/ln").Methods("GET").HandlerFunc(lnurlw_response)
	router.Path("/cb").Methods("GET").HandlerFunc(lnurlw_callback)
// lnurlp for lightning address lnurlp
	router.Path("/.well-known/lnurlp/{name}").Methods("GET").HandlerFunc(lnurlp_response)
	router.Path("/lnurlp/{name}").Methods("GET").HandlerFunc(lnurlp_callback)

	port := os.Getenv("HOST_PORT")
	if len(port) == 0 {
		port = "9000"
	}

	srv := &http.Server {
		Handler:      router,
		Addr:         ":" + port, // consider adding host
		WriteTimeout: 30 * time.Second,
		ReadTimeout:  30 * time.Second,
	}

	srv.ListenAndServe()
}
