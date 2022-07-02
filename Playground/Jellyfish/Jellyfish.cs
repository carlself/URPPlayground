using UnityEngine;

[RequireComponent(typeof(Renderer))]
public class Jellyfish : MonoBehaviour
{
    public Transform followTransform;
    private Vector3 tentaclesPosition;
    private Material material;

    void OnEnable()
    {
        // Create instance of Material, so each Jellyfish can have different rotations
        material = GetComponent<Renderer>().material;
        tentaclesPosition = transform.position + new Vector3(0, 3, 0);
    }

    private void OnDestroy()
    {
        // Cleanup Material
        Destroy(material);
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.blue;
        Gizmos.DrawSphere(tentaclesPosition, 0.1f);
    }

    void Update()
    {
        if (material == null) return;

        // Move Tentacles Position Closer if it gets more than 1 unit away
        Vector3 diff = tentaclesPosition - transform.position;
        if (diff.sqrMagnitude > 1)
        {
            tentaclesPosition -= diff * Time.deltaTime;
        }

        // Move & Rotate towards Follow Transform
        Vector3 followVector = followTransform.position - transform.position;
        float magnitude = followVector.magnitude;
        if (magnitude > 0.01f)
        {
            transform.up = followVector;
            transform.position += followVector / magnitude
                    * Mathf.Abs(Mathf.Sin(1.5f * Time.time))
                    * Time.deltaTime;
        }

        // Obtain Angle & Axis of Rotation
        Vector3 tentaclesVector = transform.position - tentaclesPosition;
        float angle = Vector3.Angle(tentaclesVector, transform.up);
        Vector3 axis = Vector3.Cross(tentaclesVector, transform.up);
        if (axis.sqrMagnitude < 0.0001f)
        {
            // If RotationAxis is 0,0,0, change it to 0,1,0
            // as it seems to cause vertices to completely disappear
            axis = Vector3.up;
            angle = 0;
        }

        // Set Material Properties, using the same Property References as in the Shader
        material.SetVector("_RotAxis", axis.normalized);
        material.SetFloat("_RotAngle", -angle);
    }
}
