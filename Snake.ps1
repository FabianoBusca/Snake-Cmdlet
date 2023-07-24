# Global variables for console dimensions
$global:consoleWidth = $null
$global:consoleHeight = $null

class Cords {
    [int]$X
    [int]$Y
}

# Function to get console dimensions
function GetConsoleDimensions {
    $global:consoleWidth = [System.Console]::WindowWidth
    $global:consoleHeight = [System.Console]::WindowHeight
}

# Function to spawn a target
function SpawnTarget {
    param (
        [ref]$tar,
        [ref]$snake
    )

    $targetBoundaryX = $global:consoleWidth - 1
    $targetBoundaryY = $global:consoleHeight - 2

    do {
        $tar.Value.X = Get-Random -Minimum 2 -Maximum $targetBoundaryX
        $tar.Value.Y = Get-Random -Minimum 2 -Maximum $targetBoundaryY
    } while ($snake.Value | Where-Object { $_.X -eq $tar.Value.X -and $_.Y -eq $tar.Value.Y })

    [System.Console]::SetCursorPosition($tar.Value.X, $tar.Value.Y)
    Write-Host "@"
}

# Function to set snake direction
function SetDirection {
    param (
        [ref]$dir
    )

    # Check if an arrow key was pressed to change the direction
    if ([System.Console]::KeyAvailable) {
        $key = [System.Console]::ReadKey($true)
        switch ($key.Key) {
            "UpArrow" {
                if ($dir.Value -ne 2) {
                    $dir.Value = 0
                }
            }
            "RightArrow" {
                if ($dir.Value -ne 3) {
                    $dir.Value = 1
                }
            }
            "DownArrow" {
                if ($dir.Value -ne 0) {
                    $dir.Value = 2
                }
            }
            "LeftArrow" {
                if ($dir.Value -ne 1) {
                    $dir.Value = 3
                }
            }
        }
    }
}

function MoveSnake {
    param (
        [ref]$snake,
        [int]$dir,
        [Cords]$tar
    )

    $width = $global:consoleWidth
    $height = $global:consoleHeight

    # Create the new head
    $newHead = New-Object Cords
    $newHead.X = $snake.Value[0].X
    $newHead.Y = $snake.Value[0].Y

    # Update the old head
    [System.Console]::SetCursorPosition($newHead.X, $newHead.Y)
    Write-Host o

    switch ($dir) {
        0 {
            $newHead.Y--
            if ($newHead.Y -eq 0) {
                exit
            }
        }
        1 {
            $newHead.X++
            if ($newHead.X -eq $width) {
                exit
            }
        }
        2 {
            $newHead.Y++
            if ($newHead.Y -eq $height - 2) {
                exit
            }
        }
        3 {
            $newHead.X--
            if ($newHead.X -eq 0) {
                exit
            }
        }
    }

    # Check the new head doesn't collide with the body
    if ($snake.Value | Where-Object { $_.X -eq $newHead.X -and $_.Y -eq $newHead.Y }) {
        exit
    }    

    # Draw and insert the new head into the list
    [System.Console]::SetCursorPosition($newHead.X, $newHead.Y)
    Write-Host O
    $snake.Value.Insert(0, $newHead)

    # Remove and erase the tail if it hasn't eaten the target
    if ($newHead.X -ne $tar.X -or $newHead.Y -ne $tar.Y) {
        $tail = $snake.Value[$snake.Value.Count - 1]
        [System.Console]::SetCursorPosition($tail.X, $tail.Y)
        Write-Host " " -NoNewline
        $snake.Value.RemoveAt($snake.Value.Count - 1)
    }
}

try {
    # Clear the console
    Clear-Host

    # Disable the cursor
    [Console]::CursorVisible = $false

    # Get the console dimensions
    GetConsoleDimensions

    # Write the score at the top
    $scoreText = "Score: 0"
    $paddingLeft = ($global:consoleWidth - $scoreText.Length) / 2
    $score = [Cords]::new()
    $score.X = $paddingLeft
    $score.Y = 0
    $scoreValue = 0

    [System.Console]::SetCursorPosition($score.X, $score.Y)
    Write-Host $scoreText

    # Create the snake
    $snakeList = New-Object System.Collections.Generic.List[Cords]
    
    # Add the head
    $head = [Cords]::new()
    $head.X = $global:consoleWidth / 2
    $head.Y = $global:consoleHeight / 2
    [System.Console]::SetCursorPosition($head.X, $head.Y)
    Write-Host O
    $snakeList.Add($head)

    # Draw the initial target
    $target = [Cords]::new()
    SpawnTarget -tar ([ref]$target)

    # Wait for an arrow key press
    while ($true) {
        $key = [System.Console]::ReadKey($true)
        if ($key.Modifiers -eq "Control" -and $key.Key -eq "C") {
            exit
        }
        if ($key.Key -in "UpArrow", "DownArrow", "LeftArrow", "RightArrow") {
            switch ($key.Key) {
                "UpArrow" {
                    $direction = 0
                }
                "RightArrow" {
                    $direction = 1
                }
                "DownArrow" {
                    $direction = 2
                }
                "LeftArrow" {
                    $direction = 3
                }
            }
            break
        }
    }

    # Game loop
    while ($true) {
        Start-Sleep -Milliseconds 50
        SetDirection -dir ([ref]$direction)
        MoveSnake -snake ([ref]$snakeList) -dir $direction -tar $target

        if ($snakeList[0].X -eq $target.X -and $snakeList[0].Y -eq $target.Y) {
            SpawnTarget -tar ([ref]$target)
            $scoreValue++
            [System.Console]::SetCursorPosition($score.X, $score.Y)
            Write-Host " " * $scoreText.Length
            [System.Console]::SetCursorPosition($score.X, $score.Y)
            Write-Host ("Score: {0}" -f $scoreValue)
        }         
    }

} finally {
    # Restore settings
    [System.Console]::SetCursorPosition(0, $global:consoleHeight - 2)
    Write-Host "Game over! Score: $scoreValue " -NoNewline
    [Console]::CursorVisible = $true
}