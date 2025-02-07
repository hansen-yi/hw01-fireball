import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  octaves: 8,
  amplitude: 0.5,
  frequency: 2.,
  'Reset' : reset,
  'Swap Colors': swap,
};
const palette = {
  color: [255, 0, 0],
  other_color: [223, 250, 122],
}

let icosphere: Icosphere;
let square: Square;
let prevTesselations: number = 5;
let cube: Cube;
let prevColor: Array<number> = [255, 0, 0];
let prevOtherColor: Array<number> = [223, 250, 122];
let time: number = 0;
let prevOctaves: number = 8;
let prevAmplitude: number = 0.5;
let prevFrequency: number = 2.;
const gui = new DAT.GUI();

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

function reset() {
  controls.amplitude = 0.5;
  controls.frequency = 2;
  palette.color = [255, 0, 0];
  palette.other_color = [223, 250, 122];
  gui.updateDisplay();
}

function swap() {
  let mainColor = prevColor;
  palette.color = prevOtherColor;
  palette.other_color = mainColor;
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  // const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  gui.addColor(palette, 'color');
  // gui.add(controls, 'octaves', 0, 32).step(2);
  gui.addColor(palette, 'other_color');
  gui.add(controls, 'Swap Colors');
  gui.add(controls, 'amplitude', 0, 5).step(0.5);
  gui.add(controls, 'frequency', 0, 5).step(0.5);
  gui.add(controls, 'Reset');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    // new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    // new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
    // new Shader(gl.VERTEX_SHADER, require('./shaders/custom-vert.glsl')),
    // new Shader(gl.FRAGMENT_SHADER, require('./shaders/noise-frag.glsl')),
    new Shader(gl.VERTEX_SHADER, require('./shaders/fire-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fire-frag.glsl')),
  ]);

  lambert.setAmplitude(0.5);
  lambert.setFrequency(2.);
  lambert.setOtherColor(vec4.fromValues(223 / 255, 250 / 255, 122 / 255, 1));

  const flat = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/flat-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/flat-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }
    // console.log(prevColor);
    if(palette.color != prevColor)
    {
      console.log(prevColor);
      prevColor = palette.color;
      lambert.setGeometryColor(vec4.fromValues(prevColor[0] / 255.0, prevColor[1] / 255.0, prevColor[2] / 255.0, 1));
    }
    if(palette.other_color != prevOtherColor)
    {
      prevOtherColor = palette.other_color;
      lambert.setOtherColor(vec4.fromValues(prevOtherColor[0] / 255.0, prevOtherColor[1] / 255.0, prevOtherColor[2] / 255.0, 1));
    }
    if(controls.octaves != prevOctaves) {
      prevOctaves = controls.octaves;
      lambert.setOctaves(prevOctaves);
    }
    if(controls.amplitude != prevAmplitude) {
      prevAmplitude = controls.amplitude;
      lambert.setAmplitude(prevAmplitude);
    }
    if(controls.frequency!= prevFrequency) {
      prevFrequency = controls.frequency;
      lambert.setFrequency(prevFrequency);
    }
    time++;

    gl.disable(gl.DEPTH_TEST);
    renderer.render(camera, flat, [
      // icosphere,
      // square,
      cube,
    ],
    vec4.fromValues(prevColor[0] / 255.0, prevColor[1] / 255.0, prevColor[2] / 255.0, 1),
    time);
    gl.enable(gl.DEPTH_TEST);
    renderer.render(camera, lambert, [
      icosphere,
      // square,
      // cube,
    ],
    vec4.fromValues(prevColor[0] / 255.0, prevColor[1] / 255.0, prevColor[2] / 255.0, 1),
    time);
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
