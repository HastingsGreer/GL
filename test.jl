import GLFW
using Images, FileIO
using ModernGL
include("util.jl")

function initWindow()

    GLFW.Init()
    # OS X-specific GLFW hints to initialize the correct version of OpenGL
    wh = 1400
    # Create a windowed mode window and its OpenGL context
    window = GLFW.CreateWindow(wh, wh, "OpenGL Example")
    # Make the window's context current
    GLFW.MakeContextCurrent(window)
    GLFW.ShowWindow(window)
    GLFW.SetWindowSize(window, wh, wh) # Seems to be necessary to guarantee that window > 0

    glViewport(0, 0, wh, wh)

    println(createcontextinfo())
    return window
end

struct Mesh
    vertexBuffer
    data
end

function genTriangles()
    # The data for our triangle
    data = GLfloat[
        0.0, 0.5, 0, 1,
        0.5, -0.5, 1, 1, 
        -0.5,-0.5, 0, 0,
        1.00, 1.05, 0, 0,
        1.05, .95, 0, 1,
        .95, .95, 1, 1
    ]
    # Generate a vertex array and array buffer for our data
    #vao = glGenVertexArray()
    #glBindVertexArray(vao)
    vbo = glGenBuffer()
    glBindBuffer(GL_ARRAY_BUFFER, vbo)
    #glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_DYNAMIC_DRAW)
    return Mesh(vbo, data)
end
function genShader()
    # Create and initialize shaders
    vsh = """
    $(get_glsl_version_string())
    in vec2 positiono;
    in vec2 tex_coord;
    uniform vec2 mousePos;
    out vec2 Tex_coord;
    void main() {
        gl_Position = vec4(tex_coord * 0.000001 + positiono + mousePos / 700 - vec2(1, 1), 0.0, 1.0);
        Tex_coord = tex_coord;
    }
    """
    fsh = """
    $(get_glsl_version_string())
    in vec4 gl_FragCoord;
    in vec2 Tex_coord;
    uniform vec2 mousePos;
    uniform sampler2D u_Texture;
    out vec4 outColor;
    void main() {
        vec4 texColor = texture(u_Texture, Tex_coord);
        outColor = texColor + (gl_FragCoord  ) / 1400;
    }
    """
    vertexShader = createShader(vsh, GL_VERTEX_SHADER)
    fragmentShader = createShader(fsh, GL_FRAGMENT_SHADER)
    program = createShaderProgram(vertexShader, fragmentShader)
    glUseProgram(program)
    positionAttribute = glGetAttribLocation(program, "positiono");
    glEnableVertexAttribArray(positionAttribute)
    glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, false, 16, C_NULL)
    println(positionAttribute)
    texCoordAttribute = glGetAttribLocation(program, "tex_coord");
    println(texCoordAttribute)
    glEnableVertexAttribArray(texCoordAttribute)
    glVertexAttribPointer(texCoordAttribute, 2, GL_FLOAT, false, 16, C_NULL + 8)
    return program
end

struct Texture
    id
    data
    width
    height
    BPP
end
function genTexture()
    
    textureID = glGenOne(glGenTextures)
    glBindTexture(GL_TEXTURE_2D, textureID)
    
    data = load("gather_art.png")[3:end, :]
    data = reinterpret.(channelview(data)[:])

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP)

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, 512, 512, 0, GL_RGBA, GL_UNSIGNED_BYTE, pointer(data)) 
    
    return Texture(textureID, data, 512, 512, 32)
end

function bind(t::Texture)
    glActiveTexture(GL_TEXTURE1)
    glBindTexture(GL_TEXTURE_2D, t.id)
end
window = initWindow()
mesh = genTriangles()
program = genShader()
texture = genTexture()

texture_uniform_slot = glGetUniformLocation(program, "u_Texture")
glUniform1i(texture_uniform_slot, 0)

# Loop until the user closes the window
mousePos = glGetUniformLocation(program, "mousePos")
function cursorCallback(_, x, y)
    glUniform2f(mousePos, x, 1400 - y)
    # GLFW.SetCursorPos(window, 700, 700)
end



GLFW.SetCursorPosCallback(window, cursorCallback)
closed = false
GLFW.SetWindowCloseCallback(window, (_) -> global closed=true)
fps = 200
function main()
    start = time()
    i = 0
    while !closed && i < 40000
        i += 1
        elapsed = time() - start
        while i > elapsed * fps
            elapsed = time() - start
        end
        theta = elapsed 
        #data_rotated = [cos(theta) sin(theta); -sin(theta) cos(theta)] * reshape(mesh.data, 4, 6)[1:2, :]
        #data_rotated =                            
        #data_rotated_flat = GLfloat.(reshape(data_rotated, 12))
        glBufferData(GL_ARRAY_BUFFER, sizeof(mesh.data), mesh.data, GL_DYNAMIC_DRAW)
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


