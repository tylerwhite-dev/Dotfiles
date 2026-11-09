#!/usr/bin/env bash

ui_color_reset=""
ui_color_heading=""
ui_color_question=""
ui_color_success=""
ui_color_error=""
ui_color_hint=""
ui_color_comment=""
ui_color_selected=""
ui_color_package=""
ui_color_group=""

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  ui_color_reset=$'\033[0m'
  ui_color_heading=$'\033[1;34m'
  ui_color_question=$'\033[1;33m'
  ui_color_success=$'\033[1;32m'
  ui_color_error=$'\033[1;31m'
  ui_color_hint=$'\033[2m'
  ui_color_comment=$'\033[0;33m'
  ui_color_selected=$'\033[1;34m'
  ui_color_package=$'\033[90m'
  ui_color_group=$'\033[1;2m'
fi

ui_timeline_frames=('●' '●' '●' '●' '◉' '◎' '○' '◌' '◌' '◌' '◌' '○' '◎' '◉' '●' '●' '●' '●' '●' '●' '●' '●' '●')
ui_timeline_frame_milliseconds=75

# Uncomment both lines of one variant below to override the defaults above.

# 01. Rotating dots.
# ui_timeline_frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
# ui_timeline_frame_milliseconds=80

# 02. Soft pulse.
# ui_timeline_frames=('·' '•' '●' '•')
# ui_timeline_frame_milliseconds=180

# 03. Rotating circle.
# ui_timeline_frames=('◐' '◓' '◑' '◒')
# ui_timeline_frame_milliseconds=140

# 04. Vertical wave.
# ui_timeline_frames=('▁' '▂' '▃' '▄' '▅' '▆' '▇' '█' '▇' '▆' '▅' '▄' '▃' '▂')
# ui_timeline_frame_milliseconds=90

# 05. Rotating arrow.
# ui_timeline_frames=('←' '↖' '↑' '↗' '→' '↘' '↓' '↙')
# ui_timeline_frame_milliseconds=100

# 06. Diamond pulse.
# ui_timeline_frames=('·' '◇' '◆' '◇')
# ui_timeline_frame_milliseconds=170

# 07. ASCII spinner.
# ui_timeline_frames=('|' '/' '-' '\')
# ui_timeline_frame_milliseconds=120

# Additional variants adapted from https://github.com/sindresorhus/cli-spinners
# Upstream names appear in brackets; intervals are kept in milliseconds.
# License: licenses/cli-spinners.txt

# 08. Dense rotating dots [dots2].
# ui_timeline_frames=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')
# ui_timeline_frame_milliseconds=80

# 09. Braille loop [dots3].
# ui_timeline_frames=('⠋' '⠙' '⠚' '⠞' '⠖' '⠦' '⠴' '⠲' '⠳' '⠓')
# ui_timeline_frame_milliseconds=80

# 10. Sweeping dots [dots4].
# ui_timeline_frames=('⠄' '⠆' '⠇' '⠋' '⠙' '⠸' '⠰' '⠠' '⠰' '⠸' '⠙' '⠋' '⠇' '⠆')
# ui_timeline_frame_milliseconds=80

# 11. Braille side sweep [dots9].
# ui_timeline_frames=('⢹' '⢺' '⢼' '⣸' '⣇' '⡧' '⡗' '⡏')
# ui_timeline_frame_milliseconds=80

# 12. Orbiting pair [dots10].
# ui_timeline_frames=('⢄' '⢂' '⢁' '⡁' '⡈' '⡐' '⡠')
# ui_timeline_frame_milliseconds=80

# 13. Orbiting single dot [dots11].
# ui_timeline_frames=('⠁' '⠂' '⠄' '⡀' '⢀' '⠠' '⠐' '⠈')
# ui_timeline_frame_milliseconds=100

# 14. Rotating pipe joints [pipe].
# ui_timeline_frames=('┤' '┘' '┴' '└' '├' '┌' '┬' '┐')
# ui_timeline_frame_milliseconds=100

# 15. Growing ellipsis [simpleDots], three columns.
# ui_timeline_frames=('.  ' '.. ' '...' '   ')
# ui_timeline_frame_milliseconds=400

# 16. Scrolling ellipsis [simpleDotsScrolling], three columns.
# ui_timeline_frames=('.  ' '.. ' '...' ' ..' '  .' '   ')
# ui_timeline_frame_milliseconds=200

# 17. Sparkling star [star].
# ui_timeline_frames=('✶' '✸' '✹' '✺' '✹' '✷')
# ui_timeline_frame_milliseconds=70

# 18. ASCII star [star2].
# ui_timeline_frames=('+' 'x' '*')
# ui_timeline_frame_milliseconds=80

# 19. Moving horizontal lines [hamburger].
# ui_timeline_frames=('☱' '☲' '☴')
# ui_timeline_frame_milliseconds=100

# 20. Horizontal fill [growHorizontal].
# ui_timeline_frames=('▏' '▎' '▍' '▌' '▋' '▊' '▉' '▊' '▋' '▌' '▍' '▎')
# ui_timeline_frame_milliseconds=120

# 21. Expanding and popping balloon [balloon].
# ui_timeline_frames=(' ' '.' 'o' 'O' '@' '*' ' ')
# ui_timeline_frame_milliseconds=140

# 22. Breathing balloon [balloon2].
# ui_timeline_frames=('.' 'o' 'O' '°' 'O' 'o' '.')
# ui_timeline_frame_milliseconds=120

# 23. Shaded noise [noise].
# ui_timeline_frames=('▓' '▒' '░')
# ui_timeline_frame_milliseconds=100

# 24. Bouncing dot [bounce].
# ui_timeline_frames=('⠁' '⠂' '⠄' '⠂')
# ui_timeline_frame_milliseconds=120

# 25. Orbiting square quarter [boxBounce].
# ui_timeline_frames=('▖' '▘' '▝' '▗')
# ui_timeline_frame_milliseconds=120

# 26. Rotating square half [boxBounce2].
# ui_timeline_frames=('▌' '▀' '▐' '▄')
# ui_timeline_frame_milliseconds=100

# 27. Rotating triangle [triangle].
# ui_timeline_frames=('◢' '◣' '◤' '◥')
# ui_timeline_frame_milliseconds=50

# 28. Orbiting arc [arc].
# ui_timeline_frames=('◜' '◠' '◝' '◞' '◡' '◟')
# ui_timeline_frame_milliseconds=100

# 29. Rotating square corners [squareCorners].
# ui_timeline_frames=('◰' '◳' '◲' '◱')
# ui_timeline_frame_milliseconds=180

# 30. Rotating circle quarters [circleQuarters].
# ui_timeline_frames=('◴' '◷' '◶' '◵')
# ui_timeline_frame_milliseconds=120

# 31. Alternating intersections [squish].
# ui_timeline_frames=('╫' '╪')
# ui_timeline_frame_milliseconds=100

# 32. Side switch [toggle].
# ui_timeline_frames=('⊶' '⊷')
# ui_timeline_frame_milliseconds=250

# 33. Square pulse [toggle4].
# ui_timeline_frames=('■' '□' '▪' '▫')
# ui_timeline_frame_milliseconds=100

# 34. Moving arrow [arrow3], five columns.
# ui_timeline_frames=('▹▹▹▹▹' '▸▹▹▹▹' '▹▸▹▹▹' '▹▹▸▹▹' '▹▹▹▸▹' '▹▹▹▹▸')
# ui_timeline_frame_milliseconds=120

# 35. Bouncing bar [bouncingBar], six columns.
# ui_timeline_frames=('[    ]' '[=   ]' '[==  ]' '[=== ]' '[====]' '[ ===]' '[  ==]' '[   =]' '[    ]' '[   =]' '[  ==]' '[ ===]' '[====]' '[=== ]' '[==  ]' '[=   ]')
# ui_timeline_frame_milliseconds=80

# 36. Bouncing ball [bouncingBall], eight columns.
# ui_timeline_frames=('( ●    )' '(  ●   )' '(   ●  )' '(    ● )' '(     ●)' '(    ● )' '(   ●  )' '(  ●   )' '( ●    )' '(●     )')
# ui_timeline_frame_milliseconds=80
