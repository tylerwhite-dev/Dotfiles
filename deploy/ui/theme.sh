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

ui_timeline_frames=('●' '●' '●' '◉' '◎' '○' '◌' '◌' '◌' '○' '◎' '◉' '●' '●' '●')
ui_timeline_frame_microseconds=115000

# Uncomment both lines of one variant below to override the defaults above.

# 01. Rotating dots.
# ui_timeline_frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
# ui_timeline_frame_microseconds=80000

# 02. Soft pulse.
# ui_timeline_frames=('·' '•' '●' '•')
# ui_timeline_frame_microseconds=180000

# 03. Rotating circle.
# ui_timeline_frames=('◐' '◓' '◑' '◒')
# ui_timeline_frame_microseconds=140000

# 04. Vertical wave.
# ui_timeline_frames=('▁' '▂' '▃' '▄' '▅' '▆' '▇' '█' '▇' '▆' '▅' '▄' '▃' '▂')
# ui_timeline_frame_microseconds=90000

# 05. Rotating arrow.
# ui_timeline_frames=('←' '↖' '↑' '↗' '→' '↘' '↓' '↙')
# ui_timeline_frame_microseconds=100000

# 06. Diamond pulse.
# ui_timeline_frames=('·' '◇' '◆' '◇')
# ui_timeline_frame_microseconds=170000

# 07. ASCII spinner.
# ui_timeline_frames=('|' '/' '-' '\')
# ui_timeline_frame_microseconds=120000

# Additional variants adapted from https://github.com/sindresorhus/cli-spinners
# Upstream names appear in brackets; intervals are converted from ms to us.
# License: licenses/cli-spinners.txt

# 08. Dense rotating dots [dots2].
# ui_timeline_frames=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')
# ui_timeline_frame_microseconds=80000

# 09. Braille loop [dots3].
# ui_timeline_frames=('⠋' '⠙' '⠚' '⠞' '⠖' '⠦' '⠴' '⠲' '⠳' '⠓')
# ui_timeline_frame_microseconds=80000

# 10. Sweeping dots [dots4].
# ui_timeline_frames=('⠄' '⠆' '⠇' '⠋' '⠙' '⠸' '⠰' '⠠' '⠰' '⠸' '⠙' '⠋' '⠇' '⠆')
# ui_timeline_frame_microseconds=80000

# 11. Braille side sweep [dots9].
# ui_timeline_frames=('⢹' '⢺' '⢼' '⣸' '⣇' '⡧' '⡗' '⡏')
# ui_timeline_frame_microseconds=80000

# 12. Orbiting pair [dots10].
# ui_timeline_frames=('⢄' '⢂' '⢁' '⡁' '⡈' '⡐' '⡠')
# ui_timeline_frame_microseconds=80000

# 13. Orbiting single dot [dots11].
# ui_timeline_frames=('⠁' '⠂' '⠄' '⡀' '⢀' '⠠' '⠐' '⠈')
# ui_timeline_frame_microseconds=100000

# 14. Rotating pipe joints [pipe].
# ui_timeline_frames=('┤' '┘' '┴' '└' '├' '┌' '┬' '┐')
# ui_timeline_frame_microseconds=100000

# 15. Growing ellipsis [simpleDots], three columns.
# ui_timeline_frames=('.  ' '.. ' '...' '   ')
# ui_timeline_frame_microseconds=400000

# 16. Scrolling ellipsis [simpleDotsScrolling], three columns.
# ui_timeline_frames=('.  ' '.. ' '...' ' ..' '  .' '   ')
# ui_timeline_frame_microseconds=200000

# 17. Sparkling star [star].
# ui_timeline_frames=('✶' '✸' '✹' '✺' '✹' '✷')
# ui_timeline_frame_microseconds=70000

# 18. ASCII star [star2].
# ui_timeline_frames=('+' 'x' '*')
# ui_timeline_frame_microseconds=80000

# 19. Moving horizontal lines [hamburger].
# ui_timeline_frames=('☱' '☲' '☴')
# ui_timeline_frame_microseconds=100000

# 20. Horizontal fill [growHorizontal].
# ui_timeline_frames=('▏' '▎' '▍' '▌' '▋' '▊' '▉' '▊' '▋' '▌' '▍' '▎')
# ui_timeline_frame_microseconds=120000

# 21. Expanding and popping balloon [balloon].
# ui_timeline_frames=(' ' '.' 'o' 'O' '@' '*' ' ')
# ui_timeline_frame_microseconds=140000

# 22. Breathing balloon [balloon2].
# ui_timeline_frames=('.' 'o' 'O' '°' 'O' 'o' '.')
# ui_timeline_frame_microseconds=120000

# 23. Shaded noise [noise].
# ui_timeline_frames=('▓' '▒' '░')
# ui_timeline_frame_microseconds=100000

# 24. Bouncing dot [bounce].
# ui_timeline_frames=('⠁' '⠂' '⠄' '⠂')
# ui_timeline_frame_microseconds=120000

# 25. Orbiting square quarter [boxBounce].
# ui_timeline_frames=('▖' '▘' '▝' '▗')
# ui_timeline_frame_microseconds=120000

# 26. Rotating square half [boxBounce2].
# ui_timeline_frames=('▌' '▀' '▐' '▄')
# ui_timeline_frame_microseconds=100000

# 27. Rotating triangle [triangle].
# ui_timeline_frames=('◢' '◣' '◤' '◥')
# ui_timeline_frame_microseconds=50000

# 28. Orbiting arc [arc].
# ui_timeline_frames=('◜' '◠' '◝' '◞' '◡' '◟')
# ui_timeline_frame_microseconds=100000

# 29. Rotating square corners [squareCorners].
# ui_timeline_frames=('◰' '◳' '◲' '◱')
# ui_timeline_frame_microseconds=180000

# 30. Rotating circle quarters [circleQuarters].
# ui_timeline_frames=('◴' '◷' '◶' '◵')
# ui_timeline_frame_microseconds=120000

# 31. Alternating intersections [squish].
# ui_timeline_frames=('╫' '╪')
# ui_timeline_frame_microseconds=100000

# 32. Side switch [toggle].
# ui_timeline_frames=('⊶' '⊷')
# ui_timeline_frame_microseconds=250000

# 33. Square pulse [toggle4].
# ui_timeline_frames=('■' '□' '▪' '▫')
# ui_timeline_frame_microseconds=100000

# 34. Moving arrow [arrow3], five columns.
# ui_timeline_frames=('▹▹▹▹▹' '▸▹▹▹▹' '▹▸▹▹▹' '▹▹▸▹▹' '▹▹▹▸▹' '▹▹▹▹▸')
# ui_timeline_frame_microseconds=120000

# 35. Bouncing bar [bouncingBar], six columns.
# ui_timeline_frames=('[    ]' '[=   ]' '[==  ]' '[=== ]' '[====]' '[ ===]' '[  ==]' '[   =]' '[    ]' '[   =]' '[  ==]' '[ ===]' '[====]' '[=== ]' '[==  ]' '[=   ]')
# ui_timeline_frame_microseconds=80000

# 36. Bouncing ball [bouncingBall], eight columns.
# ui_timeline_frames=('( ●    )' '(  ●   )' '(   ●  )' '(    ● )' '(     ●)' '(    ● )' '(   ●  )' '(  ●   )' '( ●    )' '(●     )')
# ui_timeline_frame_microseconds=80000
