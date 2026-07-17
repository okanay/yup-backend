package httpapi

type Pagination struct {
	Total int `json:"total"`
	Limit int `json:"limit"`
	Page  int `form:"page" binding:"required"`
}
