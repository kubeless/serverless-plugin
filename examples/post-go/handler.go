package kubeless

import (
	"fmt"

	"github.com/kubeless/kubeless/pkg/functions"
)

// Handler returns the given data.
func Handler(event functions.Event, context functions.Context) (string, error) {
	fmt.Println(event)
	return event.Data, nil
}
