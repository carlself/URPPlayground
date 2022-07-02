using UnityEngine;

[ExecuteInEditMode]
public class Whirlpool : MonoBehaviour
{

    public Material material;

    void Update()
    {
        if (material != null)
        {
            material.SetVector("_Position", new Vector2(transform.position.x,
               transform.position.z));
            material.SetVector("_Scale", new Vector2(transform.localScale.x,
               transform.localScale.y));
        }
    }
}