import controlP5.*;

final int N = 16;
final int SPACE = 10;
final int PANEL_WIDTH = 300;
final int CANVAS_X = PANEL_WIDTH;
final int CANVAS_Y = 0;
final int CANVAS_SIZE = 400;
final color COLOR_BG = #000000;
final color COLOR_GRID = #808080;
final float DX = (float) CANVAS_SIZE / N;
final float DY = (float) CANVAS_SIZE / N;

color[][] pixels = new color[N][N];
color curBrushColor;
int nx0;
int ny0;
int nx;
int ny;

ControlP5 cp5;

void setup() {
    size(700, 400); // this should have been (PANEL_WIDTH + CANVAS_SIZE, CANVAS_SIZE)

    PFont font = createFont("Arial", width / 50);

    cp5 = new ControlP5(this);
    cp5.addColorWheel("colorWheel", 0, 0, PANEL_WIDTH)
       .setLabelVisible(false)
       .setRGB(color(127, 0, 255))
       .setFont(font);
    cp5.addCheckBox("reverseEvenLines")
       .setPosition(SPACE, PANEL_WIDTH + SPACE)
       .setFont(font)
       .addItem("Reverse even lines", 0);
    cp5.addButton("saveImage")
       .setPosition(SPACE, cp5.get(CheckBox.class, "reverseEvenLines").getPosition()[1] + cp5.get(CheckBox.class, "reverseEvenLines").getHeight() + SPACE)
       .setLabel("Save")
       .setFont(font);
    cp5.addButton("loadImage")
       .setPosition(SPACE + cp5.get(Button.class, "saveImage").getWidth() + SPACE, cp5.get(Button.class, "saveImage").getPosition()[1])
       .setLabel("Load")
       .setFont(font);
 
    stroke(COLOR_GRID);
    for (int x = 0; x < N; x++) {
        for (int y = 0; y < N; y++) {
            pixels[x][y] = COLOR_BG;
        }
    }
}

void colorWheel() {
    curBrushColor = cp5.get(ColorWheel.class, "colorWheel").getRGB();
}

void draw() {
    if (mousePressed) {
        nx = int(float(mouseX - CANVAS_X) / DX);
        ny = int(float(mouseY - CANVAS_Y) / DY);

        if (0 <= nx && nx < N && 0 <= ny && ny < N) {
            pixels[nx][ny] = curBrushColor;
        }
    }

    drawPixels(pixels, PANEL_WIDTH, 0, DX, DY);
}

void saveImage() {
    selectOutput("Save image", "saveImageTo");
}

void saveImageTo(File f) {
    if (f == null) {
        println("There's no file");
        return;
    }

    PImage img = createImage(N, N, RGB);
    for (int x = 0; x < N; x++) {
        for (int y = 0; y < N; y++) {
            img.set(x, y, pixels[x][y]);
        }
    }
    img.save(f.getAbsolutePath());

    String codeFileName = f.getAbsolutePath() + ".c";

    try (OutputStream out = createOutput(codeFileName)) {
        out.write(imageToWs2812Code(img).getBytes("UTF-8"));
    } catch (Exception e) {
        println("Failed to write to file " + codeFileName);
    }
}

void loadImage() {
    selectInput("Load image", "loadImageFrom");
}

void loadImageFrom(File f) {
    if (f == null) {
        println("There's no file");
        return;
    }

    PImage img = loadImage(f.getAbsolutePath());
    img.resize(N, N);
    for (int x = 0; x < N; x++) {
        for (int y = 0; y < N; y++) {
            pixels[x][y] = img.get(x, y);
        }
    }
}

void drawPixels(color[][] pixels, int posX, int posY, float dx, float dy) {
    int xmax = pixels[0].length;
    int ymax = pixels.length;

    for (int x = 0; x < xmax; x++) {
        for (int y = 0; y < ymax; y++) {
            fill(pixels[x][y]);
            rect(posX + x * dx, posY + y * dy, dx, dy);
        }
    }
}

String imageToWs2812Code(PImage img) {
    StringBuilder builder = new StringBuilder("uint8_t img[] = {");

    int row = -1;
    for (int i = 0; i < img.pixels.length; i++) {
        if (i % N == 0) {
            builder.append("\n    ");
            row++;
        }

        color argb;
        if (row % 2 == 0) {
            int col = i - N * row;
            int x = N * row + N - col - 1;
            argb = img.pixels[x];
        } else {
            argb = img.pixels[i];
        }
        int r = (argb >> 16) & 0xFF;
        int g = (argb >> 8) & 0xFF;
        int b = argb & 0xFF; 
        builder.append("0x" + Integer.toHexString(g)).append(", ")
               .append("0x" + Integer.toHexString(r)).append(", ")
               .append("0x" + Integer.toHexString(b)).append(", ");
    }
    builder.append("\n};");

    return builder.toString();
}
