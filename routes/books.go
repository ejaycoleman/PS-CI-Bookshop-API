package routes

import (
	"encoding/json"
	"io/ioutil"
	"net/http"

	"bookshop-api/data"

	"github.com/go-chi/chi"
)

func Books(r chi.Router) {
	r.Get("/", getBooks)
	r.Post("/", postBook)
}

func getBooks(w http.ResponseWriter, r *http.Request) {
	books, err := data.FetchBooks()
	if err != nil {
		http.Error(w, http.StatusText(500), 500)
	}

	jbytes, err := json.Marshal(books)
	if err != nil {
		http.Error(w, http.StatusText(500), 500)
	}

	w.Header().Add("Content-Type", "application/json")
	w.Write(jbytes)
}

func postBook(w http.ResponseWriter, r *http.Request) {
	bodyBytes, err := ioutil.ReadAll(r.Body)
	if err != nil {
		http.Error(w, http.StatusText(500), 500)
	}

	var book data.Book
	err = json.Unmarshal(bodyBytes, &book)
	if err != nil {
		http.Error(w, http.StatusText(500), 500)
	}

	err = data.CreateBook(&book)
	if err != nil {
		http.Error(w, http.StatusText(500), 500)
	}

	jbytes, err := json.Marshal(book)
	if err != nil {
		http.Error(w, http.StatusText(500), 500)
	}

	w.Header().Add("Content-Type", "application/json")
	w.Write(jbytes)
}