package api

import (
	"fmt"
	"reflect"
	"strings"

	"github.com/go-playground/validator/v10"
)

type Validator struct {
	validate *validator.Validate
}

func New() *Validator {
	v := validator.New()

	v.RegisterTagNameFunc(func(fld reflect.StructField) string {
		tagTypes := []string{"json", "form", "query", "uri"}
		for _, tagType := range tagTypes {
			name, _, _ := strings.Cut(fld.Tag.Get(tagType), ",")
			if name != "" && name != "-" {
				return name
			}
		}
		return fld.Name
	})

	return &Validator{validate: v}
}

func (v *Validator) Validate(req any) []Violation {
	if err := v.validate.Struct(req); err != nil {
		return v.formatErrors(err)
	}

	return nil
}

func (v *Validator) formatErrors(err error) []Violation {
	var violations []Violation

	for _, e := range err.(validator.ValidationErrors) {
		violations = append(violations, Violation{
			Field:   e.Field(),
			Tag:     e.Tag(),
			Message: v.customErrorMessage(e),
		})
	}

	return violations
}

func (v *Validator) customErrorMessage(e validator.FieldError) string {
	field := e.Field()
	tag := e.Tag()
	param := e.Param()

	switch tag {
	case "required":
		return fmt.Sprintf("The %s field is required.", field)
	case "required_if":
		return fmt.Sprintf("The %s field is required under certain conditions.", field)
	case "email":
		return fmt.Sprintf("The %s field must be a valid email address.", field)
	case "min":
		if e.Kind() == reflect.String {
			return fmt.Sprintf("The %s field must be at least %s characters.", field, param)
		}
		return fmt.Sprintf("The minimum value for the %s field is %s.", field, param)
	case "max":
		if e.Kind() == reflect.String {
			return fmt.Sprintf("The %s field must not be greater than %s characters.", field, param)
		}
		return fmt.Sprintf("The maximum value for the %s field is %s.", field, param)
	case "len":
		if e.Kind() == reflect.String {
			return fmt.Sprintf("The %s field must be exactly %s characters.", field, param)
		}
		return fmt.Sprintf("The %s field must contain exactly %s elements.", field, param)
	case "gte":
		if e.Kind() == reflect.String {
			return fmt.Sprintf("The %s field must be at least %s characters.", field, param)
		}
		return fmt.Sprintf("The %s field must be greater than or equal to %s.", field, param)
	case "lte":
		if e.Kind() == reflect.String {
			return fmt.Sprintf("The %s field must not be greater than %s characters.", field, param)
		}
		return fmt.Sprintf("The %s field must be less than or equal to %s.", field, param)
	case "gt":
		return fmt.Sprintf("The %s field must be greater than %s.", field, param)
	case "lt":
		return fmt.Sprintf("The %s field must be less than %s.", field, param)
	case "oneof":
		return fmt.Sprintf("The %s field must be one of the following values: [%s].", field, param)
	case "alpha":
		return fmt.Sprintf("The %s field must contain only alphabetic characters.", field)
	case "alphanum":
		return fmt.Sprintf("The %s field must contain only alphanumeric characters.", field)
	case "numeric":
		return fmt.Sprintf("The %s field must contain only numeric characters.", field)
	case "url":
		return fmt.Sprintf("The %s field must be a valid URL.", field)
	case "uri":
		return fmt.Sprintf("The %s field must be a valid URI.", field)
	case "uuid":
		return fmt.Sprintf("The %s field must be a valid UUID.", field)
	case "datetime":
		return fmt.Sprintf("The %s field must be a valid date-time format.", field)
	case "contains":
		return fmt.Sprintf("The %s field must contain '%s'.", field, param)
	case "containsany":
		return fmt.Sprintf("The %s field must contain at least one of the following characters: %s.", field, param)
	case "excludes":
		return fmt.Sprintf("The %s field must not contain '%s'.", field, param)
	case "startswith":
		return fmt.Sprintf("The %s field must start with '%s'.", field, param)
	case "endswith":
		return fmt.Sprintf("The %s field must end with '%s'.", field, param)
	case "eqfield":
		return fmt.Sprintf("The %s field must be the same as the %s field.", field, param)
	case "nefield":
		return fmt.Sprintf("The %s field must be different from the %s field.", field, param)
	default:
		return fmt.Sprintf("The '%s' rule for the %s field is not satisfied.", tag, field)
	}
}
