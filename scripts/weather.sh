#!/bin/sh

weather=$(curl -s 'wttr.in/daklak?T' | head --lines=4 | tail --lines=2)
condition=$(echo "$weather" | head --lines=1 | grep -Eo '[A-Za-z]+( [A-Za-z]+)*')
temperature=$(echo "$weather" | tail --lines=1 | grep -Eo '(\+|-| )[0-9]+' | tr -d '+-')

case $(echo "$condition" | tr '[:upper:]' '[:lower:]') in
"clear" | "sunny")
    icon=""
    ;;
"partly cloudy")
    icon="杖"
    ;;
"cloudy")
    icon=""
    ;;
"overcast")
    icon=""
    ;;
"mist" | "fog" | "freezing fog")
    icon=""
    ;;
"patchy rain possible" | "patchy light drizzle" | "light drizzle" | "patchy light rain" | "light rain" | "light rain shower" | "rain")
    icon=""
    ;;
"moderate rain at times" | "moderate rain" | "heavy rain at times" | "heavy rain" | "moderate or heavy rain shower" | "torrential rain shower" | "rain shower")
    icon=""
    ;;
"patchy snow possible" | "patchy sleet possible" | "patchy freezing drizzle possible" | "freezing drizzle" | "heavy freezing drizzle" | "light freezing rain" | "moderate or heavy freezing rain" | "light sleet" | "ice pellets" | "light sleet showers" | "moderate or heavy sleet showers")
    icon="ﭽ"
    ;;
"blowing snow" | "moderate or heavy sleet" | "patchy light snow" | "light snow" | "light snow showers")
    icon="流"
    ;;
"blizzard" | "patchy moderate snow" | "moderate snow" | "patchy heavy snow" | "heavy snow" | "moderate or heavy snow with thunder" | "moderate or heavy snow showers")
    icon="ﰕ"
    ;;
"thundery outbreaks possible" | "patchy light rain with thunder" | "moderate or heavy rain with thunder" | "patchy light snow with thunder")
    icon=""
    ;;
*)
    icon=""
    ;;
esac

printf "{\"condition\":\"%s\",\"icon\":\"%s\",\"temp\":%s}" "$condition" "$icon" "$temperature"
