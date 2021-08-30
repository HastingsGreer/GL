import GLFW
using ModernGL
include("util.jl")

GLFW.Init()
# OS X-specific GLFW hints to initialize the correct version of OpenGL
wh = 600
# Create a windowed mode window and its OpenGL context
window = GLFW.CreateWindow(wh, wh, "OpenGL Example")
# Make the window's context current
GLFW.MakeContextCurrent(window)
GLFW.ShowWindow(window)
GLFW.SetWindowSize(window, wh, wh) # Seems to be necessary to guarantee that window > 0

glViewport(0, 0, wh, wh)

println(createcontextinfo())
# The data for our triangle
data = GLfloat[
    0.0, 0.5,
    0.5, -0.5,
    -0.5,-0.5,
    1.00, 1.05,
    1.05, .95,
    .95, .95
] .* 50
# Generate a vertex array and array buffer for our data
vao = glGenVertexArray()
glBindVertexArray(vao)
vbo = glGenBuffer()
glBindBuffer(GL_ARRAY_BUFFER, vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_DYNAMIC_DRAW)
# Create and initialize shaders
const vsh = """
$(get_glsl_version_string())
in vec2 position;
uniform vec2 mousePos;
void main() {
    gl_Position = vec4(position + mousePos / 300 - vec2(1, 1), 0.0, 1.0);
}
"""
const fsh = """
$(get_glsl_version_string())
#extension GL_EXT_gpu_shader4 : enable
in vec4 gl_FragCoord;
uniform vec2 mousePos;
out vec4 outColor;
void main() {
    int x = int( gl_FragCoord[0]);
    int y = int( gl_FragCoord[1]);
    int white = int(x & y);
    outColor = vec4(white, white, white, white);
}
"""
vertexShader = createShader(vsh, GL_VERTEX_SHADER)
fragmentShader = createShader(fsh, GL_FRAGMENT_SHADER)
program = createShaderProgram(vertexShader, fragmentShader)
glUseProgram(program)
positionAttribute = glGetAttribLocation(program, "position");
glEnableVertexAttribArray(positionAttribute)
glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, false, 0, C_NULL)
# Loop until the user closes the window
mousePos = glGetUniformLocation(program, "mousePos")
function cursorCallback(_, x, y)
    glUniform2f(mousePos, x, 600 - y)
    # GLFW.SetCursorPos(window, 300, 300)
end
GLFW.SetCursorPosCallback(window, cursorCallback)
closed = false
GLFW.SetWindowCloseCallback(window, (_) -> global closed=true)
fps = 200
function main()
    start = time()
    i = 0
    while !closed
        i += 1
        elapsed = time() - start
        while i > elapsed * fps
            elapsed = time() - start
        end
        theta = elapsed 
        data_rotated = [cos(elapsed) sin(elapsed); -sin(elapsed) cos(elapsed)] * reshape(data, 2, 6)
        data_rotated_flat = GLfloat.(reshape(data_rotated, 12))
        glBufferData(GL_ARRAY_BUFFER, sizeof(data), data_rotated_flat, GL_DYNAMIC_DRAW)
        # Pulse the background blue
        glClearColor(0.0, 0.0, 0, 1.0)
        glClear(GL_COLOR_BUFFER_BIT)
        # Draw our triangle
        glDrawArrays(GL_TRIANGLES, 0, 6)
        # Swap front and back buffers
        GLFW.SwapBuffers(window)
        # Poll for and process events
        GLFW.PollEvents()
    end
end
main()
GLFW.Terminate()


