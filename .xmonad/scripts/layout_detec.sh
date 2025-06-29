#!/bin/bash

# Get the current active layout using xkblayout-state
current_layout=$(xkblayout-state print %s)

# Check if the current layout contains 'my_ru'
if [[ "$current_layout" == *"my_ru"* ]]; then
    # If 'my_ru' is the current layout, display 'RU' in uppercase
    echo "RU"
else
    # Otherwise, display the full layout name in uppercase
    echo "$current_layout" | tr 'a-z' 'A-Z'
fi
