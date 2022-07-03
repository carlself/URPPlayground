using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ArrayTest : MonoBehaviour
{
    Material material;

    float[] points = new float[] {
             1, 0, 0, 0.1f,
        0, 1, 0, 0.2f,
        0, 0, 1, 0.4f,
        -1, 0, 0, 0.5f,
        0, -1, 0, 0.6f,
        0, 0, -1, 0.8f,
    };
    // Start is called before the first frame update

    void Start()
    {
        material = GetComponent<MeshRenderer>().sharedMaterial;
    }

    // Update is called once per frame
    void Update()
    {
        if (material == null) return;

        for (int i = 0; i < points.Length; i += 4)
        {
            float t = points[i + 3];
            t += Time.deltaTime;

            if (t > 1)
            {
                t = 0;
                Vector3 sphere = Random.onUnitSphere;
                if (sphere.y < 0) sphere.y = -sphere.y;

                points[i] = sphere.x;
                points[i + 1] = sphere.y;
                points[i + 2] = sphere.z;
            }

            points[i + 3] = t;
        }

        material.SetFloatArray("_Points", points);
    }
}
