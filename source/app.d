import raylib;
import raylib.raylib_types;

import std.stdio;
import std.random : uniform;
import std.datetime : MonoTime, Duration;
import std.string : format;

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
        [1, 0, 0, 0],
        [1, 1, 1, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    // L
    [
        [0, 0, 1, 0],
        [1, 1, 1, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    // O
    [
        [1, 1, 0, 0],
        [1, 1, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    // S
    [
        [0, 1, 1, 0],
        [1, 1, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    // T
    [
        [0, 1, 0, 0],
        [1, 1, 1, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    // Z
    [
        [1, 1, 0, 0],
        [0, 1, 1, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ]
];

enum SCREEN_WIDTH = 1680;
enum SCREEN_HEIGHT = 1020;
enum BOARD_WIDTH = 10;
enum BOARD_HEIGHT = 20;
enum TILE_SIZE = 30;

/// 
/// Params:
///   currentBlock = int[4][4]
///   currentBlockIndex = int
///   blockX = int
///   blockY = int
void spawnBlock(
                ref int[BOARD_WIDTH][BOARD_HEIGHT] board,
                ref int[4][4] currentBlock,
                ref int currentBlockIndex,
                ref int blockX,
                ref int blockY,
                ref int gameState,
                ref string statusMessage
            ) {
    currentBlockIndex = uniform(0, 7);
    currentBlock = tetrominoShapes[currentBlockIndex];
    blockX = 3;
    blockY = 0;

    if(checkCollision(board, currentBlock, blockX, blockY)) {
        gameState = 2; // ゲームオーバー
        statusMessage = "Game Over! Press Enter to Restart";
    }
}

/// 
/// Params:
///   board = int[BOARD_WIDTH][BOARD_HEIGHT]
///   currentBlock = int[4][4]
///   blockX = int
///   blockY = int
/// Returns: bool
bool checkCollision(
                    ref int[BOARD_WIDTH][BOARD_HEIGHT] board,
                    ref int[4][4] currentBlock, 
                    ref int blockX,
                    ref int blockY
                ) {
    // 回転したブロックで衝突をチェック
    foreach (y; 0 .. 4) {
        foreach (x; 0 .. 4) {
            int drawX = blockX + x;
            int drawY = blockY + y;
            if (currentBlock[y][x] == 1) {
                // ボードの範囲外か、すでにブロックがある場合は衝突
                if (drawX < 0 || drawX >= BOARD_WIDTH || drawY >= BOARD_HEIGHT || board[drawY][drawX] != 0) {
                    return true;
                }
            }
        }
    }
    return false;
}

/// 
/// Params:
///   board = int[BOARD_WIDTH][BOARD_HEIGHT]
///   currentBlock = int[4][4]
///   blockX = int
///   blockY = int
void fixBlock(
                ref int[BOARD_WIDTH][BOARD_HEIGHT] board,
                ref int[4][4] currentBlock,
                ref int blockX,
                ref int blockY
            ) {
    foreach (y; 0 .. 4) {
        foreach (x; 0 .. 4) {
            int drawX = blockX + x;
            int drawY = blockY + y;
            if (currentBlock[y][x] == 1) {
                if (drawX >= 0 && drawX < BOARD_WIDTH && drawY >= 0 && drawY < BOARD_HEIGHT) {
                    board[drawY][drawX] = 1;
                }
            }
        }
    }
    clearFullLines(board);  // ラインをクリア
}

/// 
/// Params:
///   currentBlock = int[4][4]
/// Returns: int
int getLeftmostX(ref int[4][4] currentBlock) {
    int minX = 4;
    foreach (y; 0 .. 4) {
        foreach (x; 0 .. 4) {
            if (currentBlock[y][x] == 1 && x < minX) {
                minX = x;
            }
        }
    }
    return minX;
}

/// 
/// Params:
///   currentBlock = int[4][4]
/// Returns: int
int getRightmostX(ref int[4][4] currentBlock) {
    int maxX = -1;
    foreach (y; 0 .. 4) {
        foreach (x; 0 .. 4) {
            if (currentBlock[y][x] == 1 && x > maxX) {
                maxX = x;
            }
        }
    }
    return maxX;
}

/// 
/// Params:
///   board = int[BOARD_WIDTH][BOARD_HEIGHT]
///   currentBlock = int[4][4]
///   blockX = int
///   blockY = int
void adjustBlockPosition(
                            ref int[BOARD_WIDTH][BOARD_HEIGHT] board,
                            ref int[4][4] currentBlock,
                            ref int blockX,
                            ref int blockY
                        ) {
    int left = getLeftmostX(currentBlock);
    int right = getRightmostX(currentBlock);

    // 左端が画面外 or 衝突してたら右にずらす
    while (blockX + left < 0 || checkCollision(board, currentBlock, blockX, blockY)) {
        blockX++;
        if (checkCollision(board, currentBlock, blockX, blockY)) {
            blockX--; // ずらしても解決しなかったら戻してbreak
            break;
        }
        left = getLeftmostX(currentBlock);
    }

    // 右端が画面外 or 衝突してたら左にずらす
    while (blockX + right >= BOARD_WIDTH || checkCollision(board, currentBlock, blockX, blockY)) {
        blockX--;
        if (checkCollision(board, currentBlock, blockX, blockY)) {
            blockX++; // ずらしても解決しなかったら戻してbreak
            break;
        }
        right = getRightmostX(currentBlock);
    }
}

/// 
/// Params:
///   currentBlock = int[4][4]
///   blockX = int
///   blockY = int
void drawBlock(
                ref int[4][4] currentBlock,
                ref int blockX,
                ref int blockY
            ) {
    foreach (y; 0 .. 4) {
        foreach (x; 0 .. 4) {
            int drawX = blockX + x;
            int drawY = blockY + y;
            if (currentBlock[y][x] == 1 && drawX >= 0 && drawX < BOARD_WIDTH && drawY >= 0 && drawY < BOARD_HEIGHT) {
                DrawRectangle(
                    SCREEN_WIDTH / 2 - BOARD_WIDTH * TILE_SIZE / 2 + drawX * TILE_SIZE,
                    SCREEN_HEIGHT / 2 - BOARD_HEIGHT * TILE_SIZE / 2 + drawY * TILE_SIZE,
                    TILE_SIZE - 1,
                    TILE_SIZE - 1,
                    Colors.MAROON
                );
            }
        }
    }
}

/// 
/// Rotate the block 90 degrees to the left (clockwise).
/// Params:
///   board = int[BOARD_WIDTH][BOARD_HEIGHT]
///   currentBlock = int[4][4]
///   blockX = int
///   blockY = int
void rotateBlockLeft(
                    ref int[BOARD_WIDTH][BOARD_HEIGHT] board,
                    ref int[4][4] currentBlock,
                    ref int blockX,
                    ref int blockY
                ) {
    int[4][4] rotatedBlock;
    foreach (y; 0 .. 4)
        foreach (x; 0 .. 4)
            rotatedBlock[3 - x][y] = currentBlock[y][x];

    if (!checkCollision(board, rotatedBlock, blockX, blockY)) {
        currentBlock = rotatedBlock;
    } else {
		tryWallKick(board, currentBlock, rotatedBlock, blockX, blockY);
	}
}

/// 
/// Rotate the block 90 degrees to the right (clockwise).
/// Params:
///   board = int[BOARD_WIDTH][BOARD_HEIGHT]
///   currentBlock = int[4][4]
///   blockX = int
///   blockY = int
void rotateBlockRight(
                    ref int[BOARD_WIDTH][BOARD_HEIGHT] board,
                    ref int[4][4] currentBlock,
                    ref int blockX,
                    ref int blockY
                ) {
    int[4][4] rotatedBlock;
    foreach (y; 0 .. 4)
        foreach (x; 0 .. 4)
            rotatedBlock[x][3 - y] = currentBlock[y][x];

    if (!checkCollision(board, rotatedBlock, blockX, blockY)) {
        currentBlock = rotatedBlock;
    } else {
		tryWallKick(board, currentBlock, rotatedBlock, blockX, blockY);
	}
}

/// 
/// Params:
///   board = int[BOARD_WIDTH][BOARD_HEIGHT]
///   currentBlock = int[4][4]
///   rotatedBlock = int[4][4]
///   blockX = int
///   blockY = int
void tryWallKick(
                    ref int[BOARD_WIDTH][BOARD_HEIGHT] board,
                    ref int[4][4] currentBlock,
                    ref int[4][4] rotatedBlock,
                    ref int blockX,
                    ref int blockY
                ) {
    // 試しに左に1マスずらしてチェック
    blockX -= 1;
    if (!checkCollision(board, rotatedBlock, blockX, blockY)) {
        currentBlock = rotatedBlock;
        return;
    }

    // 左にずらしてダメだったら元に戻して、右に1マスずらす
    blockX += 2;
    if (!checkCollision(board, rotatedBlock, blockX, blockY)) {
        currentBlock = rotatedBlock;
        return;
    }

    // それでもダメなら元の位置に戻して何もしない
    blockX -= 1;
}

/// 
/// Params:
///   board = int[BOARD_WIDTH][BOARD_HEIGHT]
///   currentBlock = int[4][4]
///   currentBlockIndex = int
///   blockX = int
///   blockY = int
void hardDrop(
                ref int[BOARD_WIDTH][BOARD_HEIGHT] board,
                ref int[4][4] currentBlock,
                ref int currentBlockIndex,
                ref int blockX,
                ref int blockY,
                ref int gameState,
                ref string statusMessage
            ) {
    while (!checkCollision(board, currentBlock, blockX, blockY)) {
        blockY++;
    }
    blockY--;           // 衝突したから1マス戻す
    fixBlock(board, currentBlock, blockX, blockY);         // 盤面に固定
    spawnBlock(board, currentBlock, currentBlockIndex, blockX, blockY, gameState, statusMessage);       // 次のブロック
}

/// 
/// Params:
///   board = int[BOARD_WIDTH][BOARD_HEIGHT]
void clearFullLines(
                    ref int[BOARD_WIDTH][BOARD_HEIGHT] board
                ) {
    // ラインが揃っているかチェックして、揃っている場合は削除
    for (int y = BOARD_HEIGHT - 1; y >= 0; y--) {
        bool isFullLine = true;
        // 各行をチェック
        foreach (x; 0 .. BOARD_WIDTH) {
            if (board[y][x] == 0) {
                isFullLine = false;
                break;
            }
        }

        // 揃っている行を削除して、上の行を1つ下にずらす
        if (isFullLine) {
            // 行を下にシフト
            for (int shiftY = y; shiftY > 0; shiftY--) {
                foreach (x; 0 .. BOARD_WIDTH) {
                    board[shiftY][x] = board[shiftY - 1][x];
                }
            }
            // 最上行をクリア
            foreach (x; 0 .. BOARD_WIDTH) {
                board[0][x] = 0;
            }
            y++;  // 1行削除したので、再度同じyをチェックする
        }
    }
}

/// 
/// 盤面の描画をする。
/// Params:
///   board = int[BOARD_WIDTH][BOARD_HEIGHT]
void drawField(
                ref int[BOARD_WIDTH][BOARD_HEIGHT] board
            ){
    // 設置されているブロックの描画
    foreach (y; 0 .. BOARD_HEIGHT) {
        foreach (x; 0 .. BOARD_WIDTH) {
            if (board[y][x] != 0) {
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
///   blockY = int
///   blockX = int
///   board = int[BOARD_WIDTH][BOARD_HEIGHT]
///   currentBlock = int[4][4]
///   currentBlockIndex = int
void drop(
            ref int blockY, 
            ref int blockX,
            ref int[BOARD_WIDTH][BOARD_HEIGHT] board, 
            ref int[4][4] currentBlock, 
            ref int currentBlockIndex,
            ref int gameState,
            ref string statusMessage
        ) {
    blockY++;
    if (checkCollision(board, currentBlock, blockX, blockY)) {
        blockY--; // 衝突したら1マス戻す
        fixBlock(board, currentBlock, blockX, blockY); // 盤面に固定
        spawnBlock(board, currentBlock, currentBlockIndex, blockX, blockY, gameState, statusMessage); // 次のブロックの生成
    }
}

void main() {
    int gameState = 0; // 0: 待機中, 1: プレイ中, 2: ゲームオーバー
    string statusMessage = "Press Enter to Start";
    int statusMessageSize = 40;
    int score = 0;

    int[BOARD_WIDTH][BOARD_HEIGHT] board = new int[BOARD_WIDTH][BOARD_HEIGHT]; // Note the order of dimensions: [height][width]
    int[4][4] currentBlock;
    int blockX = 3, blockY = 0;
    int currentBlockIndex;

    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "D テトリス");

    SetTargetFPS(24);

    MonoTime lastDrop = MonoTime.currTime;
    Duration dropInterval = 500.msecs;

    while (!WindowShouldClose()) {
        switch (gameState) {
            case 0: // 待機中
                if (IsKeyPressed(KeyboardKey.KEY_ENTER)) {
                    gameState = 1; // プレイ中に遷移
                    statusMessage = null;
                    spawnBlock(board, currentBlock, currentBlockIndex, blockX, blockY, gameState, statusMessage);
                    lastDrop = MonoTime.currTime; // 落下タイマーのリセット
                }
                break;
            case 1: // プレイ中
                // 入力処理
                if (IsKeyPressed(KeyboardKey.KEY_LEFT) || IsKeyPressedRepeat(KeyboardKey.KEY_LEFT))  	blockX--;
                if (IsKeyPressed(KeyboardKey.KEY_RIGHT) || IsKeyPressedRepeat(KeyboardKey.KEY_RIGHT)) 	blockX++;
                if (IsKeyPressed(KeyboardKey.KEY_DOWN) || IsKeyPressedRepeat(KeyboardKey.KEY_DOWN))
                    drop(blockY, blockX, board, currentBlock, currentBlockIndex, gameState, statusMessage); // 1マス下に移動
                if (IsKeyPressed(KeyboardKey.KEY_Z)) 		rotateBlockLeft(board, currentBlock, blockX, blockY);  // 回転処理
                if (IsKeyPressed(KeyboardKey.KEY_X)) 		rotateBlockRight(board, currentBlock, blockX, blockY);  // 回転処理
                if (IsKeyPressed(KeyboardKey.KEY_SPACE))  	
                    hardDrop(board, currentBlock, currentBlockIndex, blockX, blockY, gameState, statusMessage);  // ハードドロップ

                adjustBlockPosition(board, currentBlock, blockX, blockY);  // テトミノの位置補正

                // 自動で下に落ちる処理
                if (MonoTime.currTime - lastDrop > dropInterval) {
                    drop(blockY, blockX, board, currentBlock, currentBlockIndex, gameState, statusMessage);
                    lastDrop = MonoTime.currTime;
                }
                break;
            case 2: // ゲームオーバー
                if (IsKeyPressed(KeyboardKey.KEY_ENTER)) {
                    gameState = 0; // 待機中に戻る
                    statusMessage = "Press Enter to Start";
                    board = new int[BOARD_WIDTH][BOARD_HEIGHT]; // 盤面の初期化
                    currentBlock = new int[4][4];
                }
                break;
            default:
                printf("Unknown game state: %d\n", gameState);
                gameState = 0;
                break;
        }

        // 描画
        BeginDrawing();
        ClearBackground(Colors.RAYWHITE);

        drawField(board);                           // 盤面の描画
        drawBlock(currentBlock, blockX, blockY);    // ブロックの描画

        // メッセージの描画
        if (statusMessage) {
            DrawRectangle(
                SCREEN_WIDTH / 2 - MeasureText(statusMessage.ptr, statusMessageSize) / 2 - 20,
                SCREEN_HEIGHT / 2 - statusMessageSize / 2 - 10,
                MeasureText(statusMessage.ptr, statusMessageSize) + 40,
                statusMessageSize + 20,
                Color(255, 255, 255, 200)
            );
            DrawText(
                statusMessage.ptr,
                SCREEN_WIDTH / 2 - MeasureText(statusMessage.ptr, statusMessageSize) / 2,
                SCREEN_HEIGHT / 2 - statusMessageSize / 2,
                statusMessageSize,
                Colors.DARKGRAY
            );
        }

        //スコアの描画
        DrawText(
            format("Score: %7d", score).ptr,
            SCREEN_WIDTH / 2 - BOARD_WIDTH * TILE_SIZE / 2 - 150,
            SCREEN_HEIGHT / 2 - BOARD_HEIGHT * TILE_SIZE / 2 + 20,
            20,
            Colors.DARKGRAY
        );

        EndDrawing();
    }

    CloseWindow();
}
