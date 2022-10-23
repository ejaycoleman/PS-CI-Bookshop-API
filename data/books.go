package data

import (
	"github.com/pkg/errors"
)

type Book struct {
	Id      int64
	Name    string
	Author string
}

func FetchBooks() ([]Book, error) {
	conn, err := GetDbConnection()
	if err != nil {
		return nil, errors.Wrap(err, "(FetchBooks) GetConnection")
	}

	query := "SELECT * FROM books"
	rows, err := conn.Query(query)
	if err != nil {
		return nil, errors.Wrap(err, "(FetchBooks) db.Query")
	}

	books := []Book{}

	for rows.Next() {
		var book Book
		err = rows.Scan(&book.Id, &book.Name, &book.Author)
		if err != nil {
			return nil, errors.Wrap(err, "(FetchBooks) rows.Scan")
		}
		books = append(books, book)
	}

	return books, nil
}

func CreateBook(book *Book) error {
	conn, err := GetDbConnection()
	if err != nil {
		return errors.Wrap(err, "(CreateBook) GetConnection")
	}

	query := "INSERT INTO books (name, author) VALUES (?, ?)"

	result, err := conn.Exec(query, book.Name, book.Author)
	if err != nil {
		return errors.Wrap(err, "(CreateBook) conn.Exec")
	}

	id, err := result.LastInsertId()
	if err != nil {
		return errors.Wrap(err, "(CreateBook) result.LastInsertId")
	}

	book.Id = id
	return nil
}