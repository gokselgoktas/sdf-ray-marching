using UnityEngine;
using UnityEngine.Rendering;

using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class RayMarcher : MonoBehaviour
{
    [Range(1, 1000)]
    public int maximumIterationCount = 128;

    [Range(0.0001f, 0.1f)]
    public float epsilon = 0.0025f;

    private Shader m_Shader;
    public Shader shader
    {
        get
        {
            if (m_Shader == null)
                m_Shader = Shader.Find("Hidden/Ray-marcher");

            return m_Shader;
        }
    }

    private Material m_Material;
    public Material material
    {
        get
        {
            if (m_Material == null)
            {
                if (shader == null || !shader.isSupported)
                    return null;

                m_Material = new Material(shader);
            }

            return m_Material;
        }
    }

    private Camera m_Camera;
    public Camera camera_
    {
        get
        {
            if (m_Camera == null)
                m_Camera = GetComponent<Camera>();

            return m_Camera;
        }
    }

    private Mesh m_Quad;
    private Mesh quad
    {
        get
        {
            if (m_Quad == null)
            {
                Vector3[] vertices = new Vector3[4]
                {
                    new Vector3(1.0f, 1.0f, 0.0f),
                    new Vector3(-1.0f, 1.0f, 0.0f),
                    new Vector3(-1.0f, -1.0f, 0.0f),
                    new Vector3(1.0f, -1.0f, 0.0f),
                };

                int[] indices = new int[6] { 0, 1, 2, 2, 3, 0 };

                m_Quad = new Mesh();
                m_Quad.vertices = vertices;
                m_Quad.triangles = indices;
            }

            return m_Quad;
        }
    }

    private CommandBuffer m_CommandBuffer;

    void OnEnable()
    {
        camera_.depthTextureMode = DepthTextureMode.Depth;
    }

    void OnDisable()
    {
        if (camera_ != null)
        {
            if (m_CommandBuffer != null)
            {
                camera_.RemoveCommandBuffer(CameraEvent.AfterGBuffer, m_CommandBuffer);
            }

            m_CommandBuffer = null;
        }
    }

    void OnPreRender()
    {
        material.SetInt("_MaximumIterationCount", maximumIterationCount);
        material.SetFloat("_Epsilon", epsilon);

        if (m_CommandBuffer == null)
        {
            m_CommandBuffer = new CommandBuffer();
            m_CommandBuffer.name = "Ray-marcher";
            m_CommandBuffer.DrawMesh(quad, Matrix4x4.identity, material, 0, 0, null);

            camera_.AddCommandBuffer(CameraEvent.AfterGBuffer, m_CommandBuffer);
        }
    }
}
