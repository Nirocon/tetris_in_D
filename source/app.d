import raylib;
import raylib.raylib_types;

import std.stdio;
import std.random : uniform;
import std.datetime : MonoTime, Duration;
import std.string : format;
import std.conv : to;


import core.time : Duration, msecs;

enum int[4][4][7] tetrominoShapes = [
    // I
    [
        [0, 0, 0, 0],
        [1, 1, 1, 1],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    // J
    [
        [0, 0, 0, 0],
        [1, 1, 1, 0],
        [0, 0, 1, 0],
        [0, 0, 0, 0],
    ],
    // L
    [
        [0, 0, 0, 0],
        [0, 1, 1, 1],
        [0, 1, 0, 0],
        [0, 0, 0, 0],
    ],
    // O
    [
        [0, 0, 0, 0],
        [0, 1, 1, 0],
        [0, 1, 1, 0],
        [0, 0, 0, 0],
    ],
    // S
    [
        [0, 0, 0, 0],
        [0, 1, 1, 0],
        [1, 1, 0, 0],
        [0, 0, 0, 0],
    ],
    // T
    [
        [0, 0, 0, 0],
        [1, 1, 1, 0],
        [0, 1, 0, 0],
        [0, 0, 0, 0],
    ],
    // Z
    [
        [0, 0, 0, 0],
        [1, 1, 0, 0],
        [0, 1, 1, 0],
        [0, 0, 0, 0],
    ]
];

enum SCREEN_WIDTH = 1680;
enum SCREEN_HEIGHT = 1020;
enum BOARD_WIDTH = 10;
enum BOARD_HEIGHT = 20;
enum TILE_SIZE = 40;

struct MAIN_VARS {
    int gameState;
    string statusMessage;
    int statusMessageSize;
    int score;
    string use_way;

    int[BOARD_WIDTH][BOARD_HEIGHT] board;
    int[4][4] currentBlock;
    int blockX = 3, blockY;
    int currentBlockIndex;

    MonoTime lastDrop;
    Duration dropInterval;
}

/// 
/// Params:
///   mainVars = MAIN_VARS
void spawnBlock(ref MAIN_VARS mainVars) {
    mainVars.currentBlockIndex = uniqueRandom(tetrominoShapes.length);
    mainVars.currentBlock = tetrominoShapes[mainVars.currentBlockIndex];
    mainVars.blockX = 3;
    mainVars.blockY = 0;

    if(checkCollision(mainVars)) {
        mainVars.gameState = 2; // ゲームオーバー
        mainVars.statusMessage = "Game Over! Press Enter to Restart";
    }
}

///
/// 0~nの中からランダムに1つ選び返す。全て選ばれるまで同じものは選ばれない。
/// Params:
///   n = int
/// Returns: int
int uniqueRandom(int n) {
    static bool[] used;
    static int count = 0;

    // 初回呼び出し時に配列を初期化
    if (count == 0) {
        used = new bool[n];
        used[] = false;
    }

    printf("count: %d\n", count);
    if (used[0]){
        printf("used: true\n");
    } else {
        printf("used: false\n");
    }


    int index;
    do {
        index = uniform(0, n);
    } while (used[index]);

    used[index] = true;
    count++;

    if (count == n) {
        used[] = false;
        count = 0;
    }

    return index;
}

/// 
/// Params:
///   mainVars = MAIN_VARS
/// Returns: bool
bool checkCollision(ref MAIN_VARS mainVars) {
    // 回転したブロックで衝突をチェック
    foreach (y; 0 .. 4) {
        foreach (x; 0 .. 4) {
            int drawX = mainVars.blockX + x;
            int drawY = mainVars.blockY + y;
            if (mainVars.currentBlock[y][x] == 1) {
                // ボードの範囲外か、すでにブロックがある場合は衝突
                if (drawX < 0 || drawX >= BOARD_WIDTH || drawY >= BOARD_HEIGHT || mainVars.board[drawY][drawX] != 0) {
                    return true;
                }
            }
        }
    }
    return false;
}

/// 
/// Params:
///   mainVars = MAIN_VARS
void fixBlock(ref MAIN_VARS mainVars) {
    foreach (y; 0 .. 4) {
        foreach (x; 0 .. 4) {
            int drawX = mainVars.blockX + x;
            int drawY = mainVars.blockY + y;
            if (mainVars.currentBlock[y][x] == 1) {
                if (drawX >= 0 && drawX < BOARD_WIDTH && drawY >= 0 && drawY < BOARD_HEIGHT) {
                    mainVars.board[drawY][drawX] = 1;
                }
            }
        }
    }
    mainVars.score += 100;  // ブロックを固定したらスコアを加算
    clearFullLines(mainVars);  // ラインをクリア
}

/// 
/// Params:
///   mainVars = MAIN_VARS
/// Returns: int
int getLeftmostX(ref MAIN_VARS mainVars) {
    int minX = 4;
    foreach (y; 0 .. 4) {
        foreach (x; 0 .. 4) {
            if (mainVars.currentBlock[y][x] == 1 && x < minX) {
                minX = x;
            }
        }
    }
    return minX;
}

/// 
/// Params:
///   mainVars = MAIN_VARS
/// Returns: int
int getRightmostX(ref MAIN_VARS mainVars) {
    int maxX = -1;
    foreach (y; 0 .. 4) {
        foreach (x; 0 .. 4) {
            if (mainVars.currentBlock[y][x] == 1 && x > maxX) {
                maxX = x;
            }
        }
    }
    return maxX;
}

/// 
/// Params:
///   mainVars = MAIN_VARS
void adjustBlockPosition(ref MAIN_VARS mainVars) {
    int left = getLeftmostX(mainVars);
    int right = getRightmostX(mainVars);

    // 左端が画面外 or 衝突してたら右にずらす
    while (mainVars.blockX + left < 0 || checkCollision(mainVars)) {
        mainVars.blockX++;
        if (checkCollision(mainVars)) {
            mainVars.blockX--; // ずらしても解決しなかったら戻してbreak
            break;
        }
        left = getLeftmostX(mainVars);
    }

    // 右端が画面外 or 衝突してたら左にずらす
    while (mainVars.blockX + right >= BOARD_WIDTH || checkCollision(mainVars)) {
        mainVars.blockX--;
        if (checkCollision(mainVars)) {
            mainVars.blockX++; // ずらしても解決しなかったら戻してbreak
            break;
        }
        right = getRightmostX(mainVars);
    }
}

/// 
/// Params:
///   mainVars = MAIN_VARS
void drawBlock(ref MAIN_VARS mainVars) {
    foreach (y; 0 .. 4) {
        foreach (x; 0 .. 4) {
            int drawX = mainVars.blockX + x;
            int drawY = mainVars.blockY + y;
            if (mainVars.currentBlock[y][x] == 1 && drawX >= 0 && drawX < BOARD_WIDTH && drawY >= 0 && drawY < BOARD_HEIGHT) {
                DrawRectangle(
                    SCREEN_WIDTH / 2 - BOARD_WIDTH * TILE_SIZE / 2 + drawX * TILE_SIZE,
                    SCREEN_HEIGHT / 2 - BOARD_HEIGHT * TILE_SIZE / 2 + drawY * TILE_SIZE,
                    TILE_SIZE - 1,
                    TILE_SIZE - 1,
                    Color(150, 0, 0)
                );
            }
        }
    }
}

/// 
/// Rotate the block 90 degrees to the left (clockwise).
/// Params:
///   mainVars = MAIN_VARS
void rotateBlockLeft(ref MAIN_VARS mainVars) {
    int[4][4] rotatedBlock;
    foreach (y; 0 .. 4)
        foreach (x; 0 .. 4)
            rotatedBlock[3 - x][y] = mainVars.currentBlock[y][x];

    if (!checkCollision(mainVars)) {
        mainVars.currentBlock = rotatedBlock;
    } else {
		tryWallKick(mainVars, rotatedBlock);
	}
}

/// 
/// Rotate the block 90 degrees to the right (clockwise).
/// Params:
///   mainVars = MAIN_VARS
void rotateBlockRight(ref MAIN_VARS mainVars) {
    int[4][4] rotatedBlock;
    foreach (y; 0 .. 4)
        foreach (x; 0 .. 4)
            rotatedBlock[x][3 - y] = mainVars.currentBlock[y][x];

    if (!checkCollision(mainVars)) {
        mainVars.currentBlock = rotatedBlock;
    } else {
		tryWallKick(mainVars, rotatedBlock);
	}
}

/// 
/// Params:
///   mainVars = MAIN_VARS
///   rotatedBlock = int[4][4]
void tryWallKick(ref MAIN_VARS mainVars, int[4][4] rotatedBlock) {
    // 試しに左に1マスずらしてチェック
    mainVars.blockX -= 1;
    if (!checkCollision(mainVars)) {
        mainVars.currentBlock = rotatedBlock;
        return;
    }

    // 左にずらしてダメだったら元に戻して、右に1マスずらす
    mainVars.blockX += 2;
    if (!checkCollision(mainVars)) {
        mainVars.currentBlock = rotatedBlock;
        return;
    }

    // それでもダメなら元の位置に戻して何もしない
    mainVars.blockX -= 1;
}

/// 
/// Params:
///   mainVars = MAIN_VARS
void hardDrop(ref MAIN_VARS mainVars) {
    while (!checkCollision(mainVars)) {
        mainVars.blockY++;
    }
    mainVars.blockY--;           // 衝突したから1マス戻す
    fixBlock(mainVars);         // 盤面に固定
    spawnBlock(mainVars);       // 次のブロック
}

/// 
/// Params:
///   mainVars = MAIN_VARS
void clearFullLines(ref MAIN_VARS mainVars) {
    int clearedLines = 0;

    // ラインが揃っているかチェックして、揃っている場合は削除
    for (int y = BOARD_HEIGHT - 1; y >= 0; y--) {
        bool isFullLine = true;
        // 各行をチェック
        foreach (x; 0 .. BOARD_WIDTH) {
            if (mainVars.board[y][x] == 0) {
                isFullLine = false;
                break;
            }
        }

        // 揃っている行を削除して、上の行を1つ下にずらす
        if (isFullLine) {
            // 行を下にシフト
            for (int shiftY = y; shiftY > 0; shiftY--) {
                foreach (x; 0 .. BOARD_WIDTH) {
                    mainVars.board[shiftY][x] = mainVars.board[shiftY - 1][x];
                }
            }
            // 最上行をクリア
            foreach (x; 0 .. BOARD_WIDTH) {
                mainVars.board[0][x] = 0;
            }

            clearedLines++;
            y++;  // 1行削除したので、再度同じyをチェックする

            // ミノの落下間隔を短くする
            if (mainVars.dropInterval > 300.msecs) {
                mainVars.dropInterval -= 10.msecs;
            }
        }

        mainVars.score += clearedLines * clearedLines * 100;  // ラインを消したらスコアを加算
    }
}

/// 
/// 盤面の描画をする。
/// Params:
///   mainVars = MAIN_VARS
void drawField(ref MAIN_VARS mainVars) {
    // 設置されているブロックの描画
    foreach (y; 0 .. BOARD_HEIGHT) {
        foreach (x; 0 .. BOARD_WIDTH) {
            if (mainVars.board[y][x] != 0) {
                DrawRectangle(
                    SCREEN_WIDTH / 2 - BOARD_WIDTH * TILE_SIZE / 2 + x * TILE_SIZE,
                    SCREEN_HEIGHT / 2 - BOARD_HEIGHT * TILE_SIZE / 2 +  y * TILE_SIZE,
                    TILE_SIZE - 1, TILE_SIZE - 1,
                    Colors.DARKGRAY
                );
            }
        }
    }

    // 盤面の枠線の描画
    foreach (x; 0 .. BOARD_WIDTH + 1) {
        DrawLine(
            SCREEN_WIDTH / 2 - BOARD_WIDTH * TILE_SIZE / 2 + x * TILE_SIZE,
            SCREEN_HEIGHT / 2 - BOARD_HEIGHT * TILE_SIZE / 2,
            SCREEN_WIDTH / 2 - BOARD_WIDTH * TILE_SIZE / 2 + x * TILE_SIZE,
            SCREEN_HEIGHT / 2 - BOARD_HEIGHT * TILE_SIZE / 2 + BOARD_HEIGHT * TILE_SIZE,
            Colors.LIGHTGRAY
        );
    }
    foreach (y; 0 .. BOARD_HEIGHT + 1) {
        DrawLine(
            SCREEN_WIDTH / 2 - BOARD_WIDTH * TILE_SIZE / 2,
            SCREEN_HEIGHT / 2 - BOARD_HEIGHT * TILE_SIZE / 2 + y * TILE_SIZE,
            SCREEN_WIDTH / 2 - BOARD_WIDTH * TILE_SIZE / 2 + BOARD_WIDTH * TILE_SIZE,
            SCREEN_HEIGHT / 2 - BOARD_HEIGHT * TILE_SIZE / 2 + y * TILE_SIZE,
            Colors.LIGHTGRAY
        );
    }
}

/// 
/// ブロックを1マス下に移動し、衝突したら固定して新しいブロックを生成する。
/// Params:
///   mainVars = MAIN_VARS
void drop(ref MAIN_VARS mainVars) {
    mainVars.blockY++;
    if (checkCollision(mainVars)) {
        mainVars.blockY--; // 衝突したら1マス戻す
        fixBlock(mainVars); // 盤面に固定
        spawnBlock(mainVars); // 次のブロックの生成
    }
}

void main() {
    MAIN_VARS mainVars = MAIN_VARS();

    mainVars.gameState = 0, // 0: 待機中, 1: プレイ中, 2: ゲームオーバー
    mainVars.statusMessage = "Press Enter to Start",
    mainVars.statusMessageSize = 40,
    mainVars.score = 0,
    mainVars.use_way = "A/D : move\n\nSPACE : rotate\n\nS : soft drop\n\nENTER : hard drop",
    mainVars.board = new int[BOARD_WIDTH][BOARD_HEIGHT],
    mainVars.currentBlock = new int[4][4],
    mainVars.blockX = 3,
    mainVars.blockY = 0,
    mainVars.currentBlockIndex = 0,
    mainVars.lastDrop = MonoTime.currTime,
    mainVars.dropInterval = 700.msecs,

    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "D テトリス");

    SetTargetFPS(24);


    while (!WindowShouldClose()) {
        switch (mainVars.gameState) {
            case 0: // 待機中
                if (IsKeyPressed(KeyboardKey.KEY_ENTER)) {
                    mainVars.gameState = 1; // プレイ中に遷移
                    mainVars.statusMessage = null;
                    spawnBlock(mainVars);
                    mainVars.lastDrop = MonoTime.currTime; // 落下タイマーのリセット
                }
                break;
            case 1: // プレイ中
                // 入力処理
                // 左右移動 (←キー or →キー or Aキー or Dキー)
                if (IsKeyPressed(KeyboardKey.KEY_LEFT) || IsKeyPressedRepeat(KeyboardKey.KEY_LEFT) || IsKeyPressed(KeyboardKey.KEY_A) || IsKeyPressedRepeat(KeyboardKey.KEY_A))  	
                    mainVars.blockX--;
                if (IsKeyPressed(KeyboardKey.KEY_RIGHT) || IsKeyPressedRepeat(KeyboardKey.KEY_RIGHT) || IsKeyPressed(KeyboardKey.KEY_D) || IsKeyPressedRepeat(KeyboardKey.KEY_D))
                    mainVars.blockX++;
                // ソフトドロップ (↓キー or Sキー)
                if (IsKeyPressed(KeyboardKey.KEY_DOWN) || IsKeyPressedRepeat(KeyboardKey.KEY_DOWN) || IsKeyPressed(KeyboardKey.KEY_S) || IsKeyPressedRepeat(KeyboardKey.KEY_S))
                    drop(mainVars); // 1マス下に移動
                // 回転 (Qキー or Spaceキーで左回転, Eキーで右回転)
                if (IsKeyPressed(KeyboardKey.KEY_Q) || IsKeyPressed(KeyboardKey.KEY_SPACE))
                    rotateBlockLeft(mainVars);
                if (IsKeyPressed(KeyboardKey.KEY_E))
                    rotateBlockRight(mainVars);

                adjustBlockPosition(mainVars);  // テトミノの位置補正

                // ハードドロップ (Shiftキー or Enterキー or Wキー)
                if (IsKeyPressed(KeyboardKey.KEY_LEFT_SHIFT) || IsKeyPressed(KeyboardKey.KEY_RIGHT_SHIFT) || IsKeyPressed(KeyboardKey.KEY_ENTER) || IsKeyPressedRepeat(KeyboardKey.KEY_W))	
                    hardDrop(mainVars);

                // 自動で下に落ちる処理
                if (MonoTime.currTime - mainVars.lastDrop > mainVars.dropInterval) {
                    drop(mainVars);
                    mainVars.lastDrop = MonoTime.currTime;
                }
                break;
            case 2: // ゲームオーバー
                if (IsKeyPressed(KeyboardKey.KEY_ENTER)) {
                    mainVars.gameState = 0; // 待機中に戻る
                    mainVars.statusMessage = "Press Enter to Start";
                    mainVars.board = new int[BOARD_WIDTH][BOARD_HEIGHT]; // 盤面の初期化
                    mainVars.currentBlock = new int[4][4];
                    mainVars.score = 0;
                }
                break;
            default:
                printf("Unknown game state: %d\n", mainVars.gameState);
                mainVars.gameState = 0;
                break;
        }

        // 描画
        BeginDrawing();
        ClearBackground(Colors.BLACK);

        drawField(mainVars);                           // 盤面の描画
        drawBlock(mainVars);    // ブロックの描画

        // メッセージの描画
        if (mainVars.statusMessage) {
            DrawRectangle(
                SCREEN_WIDTH / 2 - MeasureText(mainVars.statusMessage.ptr, mainVars.statusMessageSize) / 2 - 20,
                SCREEN_HEIGHT / 2 - mainVars.statusMessageSize / 2 - 10,
                MeasureText(mainVars.statusMessage.ptr, mainVars.statusMessageSize) + 40,
                mainVars.statusMessageSize + 20,
                Color(0, 0, 0, 200)
            );
            DrawText(
                mainVars.statusMessage.ptr,
                SCREEN_WIDTH / 2 - MeasureText(mainVars.statusMessage.ptr, mainVars.statusMessageSize) / 2,
                SCREEN_HEIGHT / 2 - mainVars.statusMessageSize / 2,
                mainVars.statusMessageSize,
                Colors.LIGHTGRAY
            );
        }

        //スコアの描画
        DrawText(
            format("Score: %7d", mainVars.score).ptr,
            SCREEN_WIDTH / 2 - BOARD_WIDTH * TILE_SIZE / 2 - 150,
            SCREEN_HEIGHT / 2 - BOARD_HEIGHT * TILE_SIZE / 2 + 20,
            20,
            Colors.LIGHTGRAY
        );
        // 操作方法の描画
        DrawText(
            mainVars.use_way.ptr,
            SCREEN_WIDTH / 2 - BOARD_WIDTH * TILE_SIZE / 2 - 250,
            SCREEN_HEIGHT / 2 - BOARD_HEIGHT * TILE_SIZE / 2 + 70,
            20,
            Colors.LIGHTGRAY
        );

        EndDrawing();
    }

    CloseWindow();
}
