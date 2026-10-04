package shadertest;

import java.awt.image.BufferedImage;
import java.nio.file.Files;
import java.nio.file.Path;
import javax.imageio.ImageIO;

import net.fabricmc.fabric.api.client.gametest.v1.FabricClientGameTest;
import net.fabricmc.fabric.api.client.gametest.v1.context.ClientGameTestContext;

/**
 * Shot the sun/moon with the same camera for any shader pack: the camera is auto-aimed at the
 * brightest blob on screen (packs tilt the sun path differently), then the aim is reused.
 */
public class ShaderTest implements FabricClientGameTest {
    static final int WIDE_FOV = 70;
    static final int ZOOM_FOV = 30;

    float yaw;
    float pitch;

    @Override
    public void runTest(ClientGameTestContext context) {
        try (var world = context.worldBuilder().create()) {
            var server = world.getServer();
            server.runCommand("gamerule advance_time false");
            server.runCommand("weather clear");

            // Moon: phase = (day / 24000) % 8, so 24000 * k + 15000 shows phase k; same sky angle for every k
            server.runCommand("time set 15000");
            aim(context, server, "moon_aim");
            for (int phase : new int[] {0, 2, 4, 6}) {
                server.runCommand("time set " + (24000L * phase + 15000));
                shoot(context, server, "moon" + phase);
            }
            for (int time : new int[] {400, 700, 1200}) {
                server.runCommand("time set " + time);
                aim(context, server, "sun_aim");
                shoot(context, server, "sun" + time);
                // Same sun shifted down on screen, to see it crossing clouds near the horizon
                pitch -= 4f;
                shoot(context, server, "sun" + time + "_low");
                pitch += 4f;
            }
        }
    }

    void look(ClientGameTestContext context, net.fabricmc.fabric.api.client.gametest.v1.context.TestServerContext server) {
        server.runCommand(String.format(java.util.Locale.ROOT, "tp @p ~ ~ ~ %.2f %.2f", yaw, pitch));
        context.waitTicks(20);
    }

    void shoot(ClientGameTestContext context, net.fabricmc.fabric.api.client.gametest.v1.context.TestServerContext server, String name) {
        context.runOnClient(client -> client.options.fov().set(ZOOM_FOV));
        look(context, server);
        context.waitTicks(40);
        context.takeScreenshot(name);
    }

    /** Sweep the sky for the brightest blob, then refine the aim a few times. */
    void aim(ClientGameTestContext context, net.fabricmc.fabric.api.client.gametest.v1.context.TestServerContext server, String name) {
        context.runOnClient(client -> client.options.fov().set(WIDE_FOV));
        double best = -1;
        float bestYaw = 0, bestPitch = -40;
        for (float p : new float[] {-60f, -25f, 0f}) {
            for (float y = -180f; y < 180f; y += 60f) {
                yaw = y;
                pitch = p;
                look(context, server);
                double[] blob = brightest(context.takeScreenshot(name), WIDE_FOV);
                if (blob != null && blob[2] > best) {
                    best = blob[2];
                    bestYaw = y;
                    bestPitch = p;
                }
            }
        }
        yaw = bestYaw;
        pitch = bestPitch;
        for (int i = 0; i < 4; i++) {
            look(context, server);
            double[] blob = brightest(context.takeScreenshot(name), WIDE_FOV);
            if (blob == null) {
                break;
            }
            yaw += (float) blob[0];
            pitch = Math.max(-89f, Math.min(89f, pitch + (float) blob[1]));
        }
    }

    /** Returns {yawOffsetDeg, pitchOffsetDeg, brightness} of the brightest large blob (stars ignored), or null. */
    static double[] brightest(Path file, int fov) {
        try {
            BufferedImage img = ImageIO.read(Files.newInputStream(file));
            int w = img.getWidth(), h = img.getHeight() * 3 / 4;  // skip HUD / hand rows
            long[][] sum = new long[h + 1][w + 1];  // integral image of luma
            for (int y = 0; y < h; y++) {
                for (int x = 0; x < w; x++) {
                    sum[y + 1][x + 1] = luma(img.getRGB(x, y)) + sum[y][x + 1] + sum[y + 1][x] - sum[y][x];
                }
            }
            int r = 10;
            double best = -1;
            int bx = 0, by = 0;
            for (int y = r; y < h - r; y++) {
                for (int x = r; x < w - r; x++) {
                    long s = sum[y + r + 1][x + r + 1] - sum[y - r][x + r + 1] - sum[y + r + 1][x - r] + sum[y - r][x - r];
                    double mean = s / (double) ((2 * r + 1) * (2 * r + 1));
                    if (mean > best) {
                        best = mean;
                        bx = x;
                        by = y;
                    }
                }
            }
            if (best < 40) {
                return null;
            }
            double t = Math.tan(Math.toRadians(fov) / 2);
            double dx = (bx - w / 2.0) / (img.getHeight() / 2.0);
            double dy = (by - img.getHeight() / 2.0) / (img.getHeight() / 2.0);
            return new double[] {Math.toDegrees(Math.atan(dx * t)), Math.toDegrees(Math.atan(dy * t)), best};
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    static int luma(int rgb) {
        return (((rgb >> 16) & 255) * 3 + ((rgb >> 8) & 255) * 4 + (rgb & 255)) >> 3;
    }
}
